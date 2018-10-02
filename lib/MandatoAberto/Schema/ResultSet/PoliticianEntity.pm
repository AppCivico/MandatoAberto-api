package MandatoAberto::Schema::ResultSet::PoliticianEntity;
use common::sense;
use Moose;
use namespace::autoclean;

use WebService::Dialogflow;

extends "DBIx::Class::ResultSet";

has _dialogflow => (
    is         => "ro",
    isa        => "WebService::Dialogflow",
    lazy_build => 1,
);

sub sync_dialogflow {
    my ($self) = @_;

    my $politician_rs = $self->result_source->schema->resultset('Politician');

    my @entities_names;
    my $res = $self->_dialogflow->get_intents;

    for my $entity ( @{ $res->{intents} } ) {
        my $name = $entity->{displayName};

        if ( $self->skip_intent($name) == 0 ) {
            $name = lc $name;
            push @entities_names, $name;
        }
    }

    $self->result_source->schema->txn_do(
        sub{
            while ( my $politician = $politician_rs->next() ) {
                for my $entity_name (@entities_names) {
                    $self->find_or_create(
                        {
                            politician_id => $politician->id,
                            name          => $entity_name
                        }
                    );
                }
            }
        }
    );

    return 1;
}

sub sync_dialogflow_one_politician {
    my ($self, $politician_id) = @_;

	my @entities_names;
	my $res = $self->_dialogflow->get_intents;

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
                        politician_id => $politician_id,
                        name          => $entity_name
                    }
                );
            }
		}
	);

	return 1;
}

sub skip_intent {
    my ($self, $name) = @_;

    my @non_theme_intents = qw( Fallback Agradecimento Contatos FaleConosco Pergunta Saudação Trajetoria Voluntário Participar );

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

sub _build__dialogflow { WebService::Dialogflow->instance }

1;
