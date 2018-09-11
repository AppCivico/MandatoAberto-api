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

sub _build__dialogflow { WebService::Dialogflow->instance }

1;
