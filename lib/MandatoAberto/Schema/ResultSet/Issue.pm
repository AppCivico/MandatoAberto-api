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
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $entities = $_[0]->get_value('entities');

                        for ( my $i = 0; $i < @{ $entities }; $i++ ) {
                            my $entity_id = $entities->[$i];

                            my $count = $self->result_source->schema->resultset('PoliticianEntity')->search(
                                {
                                    id            => $entity_id,
                                    politician_id => $_[0]->get_value('politician_id'),
                                }
                            )->count;
                            die \['intent', "could not find intent with id $entity_id"] if $count == 0;
                        }

                        return 1;
                    }
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

            # Uma issue sempre é criada como aberta
            $values{open} = 1;

            my $issue = $self->create(\%values);

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