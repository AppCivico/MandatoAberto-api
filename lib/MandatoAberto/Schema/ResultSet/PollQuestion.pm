package MandatoAberto::Schema::ResultSet::PollQuestion;
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
                poll_id => {
                    required => 1,
                    type     => "Int",
                    post_check => sub {
                        my $poll_id = $_[0]->get_value("poll_id");
                        $self->result_source->schema->resultset("Poll")->search({ id => $poll_id })->count;
                    },
                },
                content => {
                    required => 1,
                    type     => "Str",
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

            my $poll_question = $self->create(
                { ( map { $_ => $values{$_} } qw(poll_id content) ) }
            );

            return $poll_question;
        }
    };
}

1;