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
                use DDP; p $fb_id;
                my $recipient = $self->result_source->schema->resultset('Recipient')->search( { fb_id => $fb_id } )->next
                  or die \['fb_id', 'invalid'];
                $values{recipient_id} = $recipient->id;

                my $question_code = delete $values{code};
                my $question      = $self->result_source->schema->resultset('QuestionnaireQuestion')->search( { code => $question_code } )->next
                  or die \['code', 'invalid'];

                $values{question_id}          = $question->id;
                $values{questionnaire_map_id} = $question->questionnaire_map_id;

                # Caso seja a última pergunta, devo atualizar o boolean de quiz preenchido do recipient
                use DDP; p $answer;
                $answer = $self->create(\%values);
                $answer->update_stash;

                # @followup_messages = $answer->followup_messages if $answer->has_followup_messages;

                # if ( $question_map->category_id == 1 ) {
                #     # Caso a resposta seja da pergunta 'A1' devo atualizar a coluna 'city' do recipient
                #     # com o conteúdo da resposta
                #     if ( $answer->question->code eq 'A1' ) {
                #         $recipient->update( { city => $answer->answer_value } );
                #     }

                #     $pending_question_data = $recipient->get_next_question_data($category);

                #     if ( defined $pending_question_data->{question} ) {

                #         if ( $next_question->{code} eq 'A2' ) {

                #             if ($answer->answer_value =~ /^(15|16|17|18|19)$/) {
                #                 $finished_quiz = 0;
                #             }
                #             else {
                #                 $finished_quiz = 1;
                #             }
                #         }
                #         elsif ( $next_question->{code} eq 'A1' ) {

                #             if ($answer->answer_value =~ /^(1|2|3)$/) {
                #                 $finished_quiz = 0;
                #             }
                #             else {
                #                 $finished_quiz = 1;
                #             }
                #         }
                #         else {
                #             $finished_quiz = 0;

                #         }
                #     }
                #     else {
                #         $recipient->recipient_flag->update( { finished_quiz => 1 } );
                #         $finished_quiz = 1;

                #         my $is_eligible_for_research = $recipient->is_eligible_for_research;

                #         eval { $simprep_url = $recipient->register_simprep if $answer->question->code eq 'AC9' && $answer->answer_value eq '1' };
                #         $integration_failed = 1 if $@;

                #         %flags = $answer->flags;
                #     }
                # }
                # elsif ($question_map->category_id == 2) {
                #     $pending_question_data = $recipient->get_next_question_data($category);

                #     if ( !$pending_question_data->{question} ) {
                #         $recipient->build_screening_report;
                #         %flags = $answer->flags;
                #         $recipient->reset_screening;

                #         $finished_quiz = 1;
                #     }
                #     else {
                #         $finished_quiz = 0;
                #     }
                # }
                # else {
                #     $pending_question_data = $recipient->get_next_question_data($category);

                #     if ( defined $pending_question_data->{question} ) {
                #         $finished_quiz = 0;
                #     }
                #     else {
                #         $finished_quiz = 1;
                #     }
                # }

            });

            return {
                # answer             => $answer,
                # finished_quiz      => $finished_quiz,
                # integration_failed => $integration_failed,

                # %flags,

                # (
                #     scalar @followup_messages > 0 ?
                #     ( followup_messages => [ map { $_ } @followup_messages ] ) : ()
                # ),

                # (
                #     defined $simprep_url ?
                #     ( offline_pre_registration_form => $simprep_url ) : ( )
                # )
            };
        }
    };
}

1;