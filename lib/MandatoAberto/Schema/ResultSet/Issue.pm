package MandatoAberto::Schema::ResultSet::Issue;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required   => 1,
                    type       => "Str",
                },
                entities => {
                    required   => 0,
                    type       => 'HashRef'
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $issue;
            $self->result_source->schema->txn_do(sub {
                # Uma issue sempre é criada como aberta
                $values{open} = 1;

                my $politician = $self->result_source->schema->resultset('Politician')->find( $values{politician_id} );
                my $recipient  = $politician->recipients->find($values{recipient_id});
                my $entity_rs  = $self->result_source->schema->resultset('Entity');

                my @entities_id;
                if ( $values{entities} ) {
                    my $entity_val = $values{entities};

                    my $intent = $entity_val->{result}->{metadata}->{intentName};
                    die \['intentName', 'missing'] unless $intent;

                    my $upsert_entity = $politician->politician_entities->find_or_create( { name => $intent } );

                    $recipient->add_to_politician_entity( $upsert_entity->id );
                    push @entities_id, $upsert_entity->id;
                }

                $issue = $self->create(
                    {
                        %values,
                        peding_entity_recognition => $values{entities} ? 0 : 1,
                        ( $values{entities} ? (entities => \@entities_id) : () )
                    }
                );
            });

            return $issue;
        }
    };
}

sub get_politician_open_issues {
    my ($self) = @_;

    return $self->search( { open => 1 } );
}

sub get_open_issues_created_today {
    my ($self) = @_;

    return $self->search(
        {
            open       => 1,
            created_at => { '>=' => "yesterday()" }
        }
    );
}

1;