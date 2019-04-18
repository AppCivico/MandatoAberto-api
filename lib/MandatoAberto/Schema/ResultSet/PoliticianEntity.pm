package MandatoAberto::Schema::ResultSet::PoliticianEntity;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw( is_test );

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

    my $organization_chatbot_rs = $self->result_source->schema->resultset('OrganizationChatbot')->search(
        { 'organization_chatbot_general_config.dialogflow_config_id' => \'IS NOT NULL' },
        {
            prefetch => { 'organization_chatbot_general_config' => 'dialogflow_config' },
            order_by => { -asc => 'dialogflow_config.project_id' }
        }
    );

    my $project_id      = '';
    my $last_project_id = '';

    my @entities_names;
    my $res;

    $self->result_source->schema->txn_do(
        sub{
            while ( my $organization_chatbot = $organization_chatbot_rs->next() ) {
                my $chatbot_config     = $organization_chatbot->general_config;
                my $dialogflow_project = $chatbot_config->dialogflow_config;

                $project_id = $dialogflow_project->project_id;

                $res             = $self->_dialogflow->get_intents( project => $dialogflow_project ) if $last_project_id ne $project_id;
                $last_project_id = $project_id;

                for my $entity ( @{ $res->{intents} } ) {
                    my $name = $entity->{displayName};

                    if ( $self->skip_intent($name) == 0 ) {
                        $name = lc $name;
                        push @entities_names, $name;
                    }
                }

                for my $entity_name (@entities_names) {
                    $self->find_or_create(
                        {
                            organization_chatbot_id => $organization_chatbot->id,
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

				my $knowledge_base_rs       = $self->result_source->schema->resultset('PoliticianKnowledgeBase')->search( { organization_chatbot_id => $organization_chatbot->id } );
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
        }
    );

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
