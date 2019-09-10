use utf8;
package MandatoAberto::Schema::Result::QuestionnaireAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::QuestionnaireAnswer

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<questionnaire_answer>

=cut

__PACKAGE__->table("questionnaire_answer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'questionnaire_answer_id_seq'

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 questionnaire_map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer_value

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "questionnaire_answer_id_seq",
  },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "questionnaire_map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer_value",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<questionnaire_answer_recipient_id_question_id_key>

=over 4

=item * L</recipient_id>

=item * L</question_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "questionnaire_answer_recipient_id_question_id_key",
  ["recipient_id", "question_id"],
);

=head1 RELATIONS

=head2 question

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::QuestionnaireQuestion>

=cut

__PACKAGE__->belongs_to(
  "question",
  "MandatoAberto::Schema::Result::QuestionnaireQuestion",
  { id => "question_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 questionnaire_map

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::QuestionnaireMap>

=cut

__PACKAGE__->belongs_to(
  "questionnaire_map",
  "MandatoAberto::Schema::Result::QuestionnaireMap",
  { id => "questionnaire_map_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 recipient

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "MandatoAberto::Schema::Result::Recipient",
  { id => "recipient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-09-02 11:23:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zZ/UpOXU4R15iwWZZzb0TQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use Scalar::Util qw( looks_like_number );

sub update_stash {
    my ($self, $finished) = @_;

    my $recipient = $self->recipient;
    my $stash     = $recipient->questionnaire_stashes->search( { questionnaire_map_id => $self->questionnaire_map_id } )->next;
    my $question  = $self->question;
    my $rules     = $question->rules_parsed;

    $self->result_source->schema->txn_do(sub {
        if ( !$rules ) {
            # Caso não tenham rules, verifico se há perguntas pendentes
            my $next_question = $stash->next_pending_question;

            if ( !defined $next_question->{question} ) {
                $stash->update( { finished => 1 } )
            }
        }

        my $answer = $self->answer_value;

        my $conditions_satisfied;
        if ( $rules->{qualification_conditions} && scalar @{ $rules->{qualification_conditions} } > 0 ) {
            # Verificando se a condição de qualificação é a multipla escolha
            # ou uma flag
            if ( looks_like_number( $rules->{qualification_conditions}->[0] ) ) {
                $conditions_satisfied = grep { $_ eq $answer } @{ $rules->{qualification_conditions} };
            }
            else {
                # São flags
                # my %recipient_flags = $recipient->all_flags;

                # $conditions_satisfied = grep { $recipient_flags{$_} == 1 } @{ $rules->{qualification_conditions} };
            }

            if ( $conditions_satisfied == 0 ) {
                $stash->update( { finished => 1 } );
            }

        }

        if ( $rules->{logic_jumps} && scalar @{ $rules->{logic_jumps} } > 0 ) {

            for my $logic_jump ( @{ $rules->{logic_jumps} } ) {
                # Ao validar essa resposta devo verificar que há respostas de texto livre
                # ( no caso números positivos inteiros )
                # E também respostas de multipla escolha
                if ( ref $logic_jump->{values} eq 'ARRAY' ) {
                    $conditions_satisfied = grep { $_ eq $answer } @{ $logic_jump->{values} };

                    if ( $conditions_satisfied == 0 ) {
                        $stash->remove_question($logic_jump->{code}) unless $self->question->code eq 'AC1';
                    }
                }
                elsif ( ref $logic_jump->{values} eq 'HASH' ) {
                    my $operator = $logic_jump->{values}->{operator} or die \['operator', 'missing'];
                    my $value    = $logic_jump->{values}->{value};
                    die \['value', 'missing'] unless defined $value;

                    if ( $operator eq '==' ) {
                        $conditions_satisfied = int( $answer == $value );
                    }
                    elsif ( $operator eq '>' ) {
                        $conditions_satisfied = $answer > $value ? 1 : 0;
                    }
                    elsif ( $operator eq '<' ) {
                        $conditions_satisfied = $answer < $value ? 1 : 0;
                    }
                    else {
                        die \['operator', 'invalid'];
                    }

                    if ( $conditions_satisfied == 0 ) {
                        $stash->remove_question($logic_jump->{code});
                    }

                }
                else {
                    die \['logic_jumps', 'invalid'];
                }

            }
        }

        my $next_question = $stash->next_pending_question;
        if ( !$next_question->{question} ) {
            $stash->update( { finished => 1 } );
        }

    });

}

sub followup_messages {
    my $self = shift;

    my $answer = $self->answer_value;
    my $rules  = $self->question->rules_parsed;
    my $stash  = $self->recipient->questionnaire_stashes->search( { questionnaire_map_id => $self->questionnaire_map_id } )->next;

    my @followup_messages;
    if ( $rules->{followup_messages} && scalar @{ $rules->{followup_messages} } > 0 ) {

        for my $followup_message ( @{ $rules->{followup_messages} } ) {
            if ( defined $followup_message->{conditions} ) {
                my $conditions_satisfied = grep { $_ eq $answer } @{ $followup_message->{conditions} };
                next if !$conditions_satisfied;
            }

            push @followup_messages, $followup_message->{text}
        }
    }

    if ( $stash->finished ) {
        my @messages_to_send_after_finish = $stash->messages_to_send_after_finish;
        push @followup_messages, @messages_to_send_after_finish;
    }

    return @followup_messages;
}

__PACKAGE__->meta->make_immutable;
1;
