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
    my $res = $self->_dialogflow->get_entities;

    for my $entity ( @{ $res->{entityTypes} } ) {
        push @entities_names, $entity->{displayName};
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

sub entity_exists {
    my ($self, $name) = @_;

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

    my @entities_names = $self->search(undef)->get_column('id')->all();

    return $self->search(
        \[ <<'SQL_QUERY', @entities_names ],
            EXISTS( SELECT 1 FROM politician_knowledge_base WHERE ? = ANY(entities::int[]) )
SQL_QUERY
    );
}

sub _build__dialogflow { WebService::Dialogflow->instance }

1;
