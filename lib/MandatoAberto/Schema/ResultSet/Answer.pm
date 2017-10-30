package MandatoAberto::Schema::ResultSet::Answer;
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
                question_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $question_id = $_[0]->get_value("question_id");
                        $self->result_source->schema->resultset("Question")->search({ id => $question_id })->count;
                    },
                },
                politician_id => {
                    required => 1,
                    type     => "Int"
                },
                content => {
                    required   => 1,
                    type       => "Str",
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

            my $dialog = $self->create(
                { ( map { $_ => $values{$_} } qw(question_id politician_id content) ) }
            );

            return $dialog;
        }
    };
}

1;