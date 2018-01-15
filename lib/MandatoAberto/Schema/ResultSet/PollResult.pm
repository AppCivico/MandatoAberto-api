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

                        $self->result_source->schema->resultset("Recipient")->search({ id => $citizen_id })->count;
                    }
                },
                poll_question_option_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $option_id = $_[0]->get_value("poll_question_option_id");

                        $self->result_source->schema->resultset("PollQuestionOption")->search({ id => $option_id })->count;
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

            # Devo permitir apenas uma resposta por enquete
            my $poll_id = $self->result_source->schema->resultset("Poll")->search(
                { 'poll_question_options.id' => $values{poll_question_option_id} },
                { prefetch => [ 'poll_questions', { 'poll_questions' => "poll_question_options" } ] }
            )->next->id;

            my $poll_citizen_answer = $self->result_source->schema->resultset("PollResult")->search(
                {
                    'citizen.id' => $values{citizen_id},
                    'poll.id'    => $poll_id
                },
                { prefetch => [ 'poll_question_option', { 'poll_question_option' => { 'poll_question' => 'poll' } }, 'citizen' ] }
            )->count;
            die \["poll_question_option_id", "citizen alredy answered poll"] if $poll_citizen_answer;

            my $poll_result = $self->create(\%values);

            return $poll_result;
        }
    };
}

1;
