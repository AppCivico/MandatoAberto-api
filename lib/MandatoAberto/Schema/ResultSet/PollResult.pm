package MandatoAberto::Schema::ResultSet::PollResult;
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
                citizen_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $citizen_id = $_[0]->get_value("citizen_id");

                        $self->result_source->schema->resultset("Citizen")->search({ id => $citizen_id })->count;
                    }
                },
                option_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $option_id = $_[0]->get_value("option_id");

                        $self->result_source->schema->resultset("QuestionOption")->search({ id => $option_id })->count;
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

            my $poll_result = $self->create(\%values);

            return $poll_result;
        }
    };
}

1;