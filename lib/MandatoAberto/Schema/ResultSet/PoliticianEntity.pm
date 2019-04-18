package MandatoAberto::Schema::ResultSet::PoliticianEntity;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw( is_test );
use DDP;

use WebService::Dialogflow;

extends "DBIx::Class::ResultSet";

has _dialogflow => (
    is         => "ro",
    isa        => "WebService::Dialogflow",
    lazy_build => 1,
);

sub _build__dialogflow { WebService::Dialogflow->instance }

sub sync_dialogflow {
    my ($self) = @_;

    my $dialogflow_project_rs = $self->result_source->schema->resultset('DialogflowConfig');

    eval {
        while ( my $project = $dialogflow_project_rs->next() ) {
            print STDERR "\n Project_google_id: " . $project->project_id;

            # Buscando intents no DialogFlow
            my @intents_names;
            my $res = $self->_dialogflow->get_intents( project => $project );

            for my $intent ( @{ $res->{intents} } ) {
                my $name = $intent->{displayName};

                if ( $self->skip_intent($name) == 0 ) {
                    # Padronizando tudo em lower case.
                    $name = lc $name;
                    push @intents_names, $name;
                }
            }

            $self->result_source->schema->txn_do( sub {
                # Preparando valores para o insert
                my @values;

                my @chatbots_configs = $project->chatbots_using->all();
                for my $chatbot_config ( @chatbots_configs ) {
                    my $chatbot_id = $chatbot_config->organization_chatbot->id;

                    for my $intent_name (@intents_names) {
                        push @values, "($chatbot_id, '$intent_name', '$intent_name')";
                    }
                }

                # Realizando INSERT com ON CONFLICT DO NOTHING
                if ( scalar @values > 0 ) {
                    $self->result_source->schema->storage->dbh_do(
                        sub {
                            my ($storage, $dbh, @cols) = @_;
                            my $values = join ',', @cols;
                            $dbh->do("INSERT INTO politician_entity (organization_chatbot_id, name, human_name) VALUES $values ON CONFLICT DO NOTHING");
                        },
                        @values
                    );
                }

                # Após criar as entities
                # deleto qualquer uma que seja do chatbot
                # mas não está com o nome na lista
                my $intents_to_be_deleted = $self->search( { name => { -not_in => \@intents_names } } );

                while ( my $intent_to_be_deleted = $intents_to_be_deleted->next() ) {
                    my $knowledge_base_rs       = $self->result_source->schema->resultset('PoliticianKnowledgeBase');
                    my $knowledge_base_stats_rs = $self->result_source->schema->resultset('PoliticianEntityStat');

                    # Deletando a intent e suas relações
                    $knowledge_base_stats_rs->search(
                        {
                            politician_entity_id => $intent_to_be_deleted->id
                        }
                    )->delete;

                    $knowledge_base_rs->search(
                            \["? = ANY(entities)", $intent_to_be_deleted->id]
                    )->delete;

                    $intents_to_be_deleted->delete();
                }
            });
        }
    };
    die $@ if $@;

    return 1;
}

sub sync_dialogflow_one_chatbot {
    my ($self, $organization_chatbot_id) = @_;

    my @entities_names;

    my $chatbot = $self->result_source->schema->resultset('OrganizationChatbot')->find($organization_chatbot_id);

    my $project = $chatbot->general_config->dialogflow_config;
    my $res     = $self->_dialogflow->get_intents( project => $project );

    for my $entity ( @{ $res->{intents} } ) {
        my $name = $entity->{displayName};

        if ( $self->skip_intent($name) == 0 ) {
            $name = lc $name;
            push @entities_names, $name;
        }
    }

    $self->result_source->schema->txn_do(
        sub{
            for my $entity_name (@entities_names) {
                $self->find_or_create(
                    {
                        organization_chatbot_id => $chatbot->id,
                        name                    => $entity_name,
                        human_name              => $entity_name
                    },
                    { key => 'chatbot_id_name' }
                );
            }

            # Após criar as entities
            # deleto qualquer uma que seja do chatbot
            # mas não está com o nome na lista
            my $intents_to_be_deleted = $self->search( { name => { -not_in => \@entities_names } } );

            my $knowledge_base_rs       = $self->result_source->schema->resultset('PoliticianKnowledgeBase')->search( { organization_chatbot_id => $chatbot->id } );
            my $knowledge_base_stats_rs = $self->result_source->schema->resultset('PoliticianEntityStat');
            while ( my $intent_to_be_deleted = $intents_to_be_deleted->next() ) {
                $knowledge_base_stats_rs->search(
                    {
                        politician_entity_id => $intent_to_be_deleted->id
                    }
                )->delete;

                $knowledge_base_rs->search(
                        \["? = ANY(entities)", $intent_to_be_deleted->id]
                )->delete;
            }

            $intents_to_be_deleted->delete();
        }
    );

    return 1;
}

sub skip_intent {
    my ($self, $name) = @_;

    my @non_theme_intents = (
        'Fallback', 'Agradecimento', 'Contatos', 'FaleConosco', 'Pergunta', 'Saudação',
        'Trajetoria', 'Voluntário', 'Participar', 'default welcome intent',
        'default fallback intent', 'teste', 'test', 'Teste', 'pedido de produtos',
        'pedido de assistência - jurídica', 'pedido de emprego',
        'pedido de assistência - previdência', 'pedido de assistência - saúde',
        'Default Welcome Intent', 'Default Fallback Intent', 'Greetings', 'greetings',
        'Quiz', 'quiz', 'Sobre Amanda', 'sobre amanda', 'Inserir Token', 'inserir token'
    );

    my $skip_intent = grep { $_ eq $name } @non_theme_intents;

    return $skip_intent;
}

sub entity_exists {
    my ($self, $name) = @_;

    $name = lc $name;

    return $self->search(
        {
            '-and' => [
                \[ <<'SQL_QUERY', $name ],
                    EXISTS( SELECT 1 FROM politician_entity WHERE name = ? )
SQL_QUERY
            ],
        }
    )->count > 0 ? 1 : 0;
}

sub entities_with_available_knowledge_bases {
    my ($self) = @_;

    return $self->search(
        \[ <<'SQL_QUERY' ],

SQL_QUERY
    );
}

sub extract_metrics {
    my ($self, %opts) = @_;

    $self = $self->search_rs( { 'me.created_at' => { '>=' => \"NOW() - interval '$opts{range} days'" } } ) if $opts{range};

    my $most_significative_entity = $self->search(
        undef,
        { order_by => { -desc => 'recipient_count' } }
    )->first;

    return {
        # Contagem total de temas
        count             => $self->count,
        description     => 'Aqui você verá as métricas sobre seus temas.',
        suggested_actions => [
            {
                alert             => '',
                alert_is_positive => 0,
                link              => '',
                link_text         => 'Ver temas'
            },
        ],
        sub_metrics => [
            # Métrica: o tema mais popular
            (
                $self->count > 0 ?
                (
                    {
                        text              => $most_significative_entity ? $most_significative_entity->name . ' é o seu tema mais popular' : undef,
                        suggested_actions => []
                    },
                ) : ( )
            )
        ]
    }
}

1;
