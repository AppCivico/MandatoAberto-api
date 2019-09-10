package MandatoAberto::Schema::ResultSet::QuestionnaireAnswer;
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
                fb_id => {
                    required   => 1,
                    type       => "Str"
                },
                code => {
                    required   => 1,
                    type       => "Str"
                },
                answer_value => {
                    required   => 1,
                    type       => "Str",
                },
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

            my ($answer, $finished_quiz, %flags, @followup_messages, $simprep_url);
            $self->result_source->schema->txn_do( sub {
                # Pegando recipient pelo fb_id
                my $fb_id = delete $values{fb_id};
                my $recipient = $self->result_source->schema->resultset('Recipient')->search( { fb_id => $fb_id } )->next
                  or die \['fb_id', 'invalid'];
                $values{recipient_id} = $recipient->id;

                my $question_code = delete $values{code};
                my $question      = $self->result_source->schema->resultset('QuestionnaireQuestion')->search( { code => $question_code } )->next
                  or die \['code', 'invalid'];

                $values{question_id}          = $question->id;
                $values{questionnaire_map_id} = $question->questionnaire_map_id;

                $answer = $self->create(\%values);
                $answer->update_stash;

                @followup_messages = $answer->followup_messages;
            });

            return {
                answer            => $answer,
                followup_messages => \@followup_messages
            };
        }
    };
}

1;