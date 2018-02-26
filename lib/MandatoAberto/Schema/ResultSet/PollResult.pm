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
                recipient_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $recipient_id = $_[0]->get_value("recipient_id");

                        $self->result_source->schema->resultset("Recipient")->search({ id => $recipient_id })->count;
                    }
                },
                poll_question_option_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $option_id = $_[0]->get_value("poll_question_option_id");

                        $self->result_source->schema->resultset("PollQuestionOption")->search({ id => $option_id })->count;
                    }
                },
                origin => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $origin = $_[0]->get_value("origin");

                        die \["origin", "must be 'dialog' or 'propagate'"] unless $origin =~ m{^(propagate|dialog){1}$};
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

            my $poll_recipient_answer = $self->result_source->schema->resultset("PollResult")->search(
                {
                    'recipient.id' => $values{recipient_id},
                    'poll.id'      => $poll_id
                },
                { prefetch => [ 'poll_question_option', { 'poll_question_option' => { 'poll_question' => 'poll' } }, 'recipient' ] }
            )->count;
            
            # Por enquanto um recipient poderá responder tanto via dialog quanto via propagate
            # die \["poll_question_option_id", "recipient alredy answered poll"] if $poll_recipient_answer;

            my $poll_result = $self->create(\%values);

            return $poll_result;
        }
    };
}

1;
