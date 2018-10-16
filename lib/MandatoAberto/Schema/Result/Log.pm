use utf8;
package MandatoAberto::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Log

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

=head1 TABLE: C<logs>

=cut

__PACKAGE__->table("logs");

=head1 ACCESSORS

=head2 timestamp

  data_type: 'timestamp'
  is_nullable: 0

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 action_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 field_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "timestamp",
  { data_type => "timestamp", is_nullable => 0 },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "action_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "field_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 RELATIONS

=head2 action

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::LogAction>

=cut

__PACKAGE__->belongs_to(
  "action",
  "MandatoAberto::Schema::Result::LogAction",
  { id => "action_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-09 15:33:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6epwA0AgvWTTEMixQ5CNbA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub description {
    my ($self) = @_;

    my $action_name = $self->action->name;

    # Tratando diferença entre logs de recipient e de admin
    my ($politician_name, $recipient_name);
    if ( $self->action->is_recipient ) {
        $recipient_name = $self->recipient->name;
    }
    else {
        $politician_name = $self->politician->name;
    }

    my $ret;
    if ( $action_name eq 'WENT_TO_FLOW' ) {
        my $chatbot_step = $self->result_source->schema->resultset('ChatbotStep')->find( $self->field_id );
        my $human_name   = $chatbot_step->human_name;

        $ret = "$recipient_name acessou o fluxo '$human_name'.";
    }
    elsif ( $action_name eq 'ANSWERED_POLL' ) {
        my $poll_question_option = $self->result_source->schema->resultset('PollQuestionOption')->find( $self->field_id );
        my $content              = $poll_question_option->content;

        $ret = "$recipient_name respondeu: '$content' para a enquete.";
    }
    elsif ( $action_name eq 'ASKED_ABOUT_ENTITY' ) {
        my $entity     = $self->result_source->schema->resultset('PoliticianEntity')->find( $self->field_id );
        my $human_name = $entity->human_name;

        $ret = "$recipient_name perguntou sobre o tema: '$human_name'.";
    }
    elsif ( $action_name eq 'ACTIVATED_NOTIFICATIONS' ) {
        $ret = "$recipient_name ativou as notificações.";
    }
    elsif ( $action_name eq 'DEACTIVATED_NOTIFICATIONS' ) {
        $ret = "$recipient_name desativou as notificações.";
    }
    elsif ( $action_name eq 'INFORMED_CELLPHONE' ) {
        $ret = "$recipient_name informou o telefone celular.";
    }
    elsif ( $action_name eq 'INFORMED_EMAIL' ) {
        $ret = "$recipient_name informou o e-mail.";
    }
    elsif ( $action_name eq 'UPDATED_POLITICIAN_PROFILE' ) {
        $ret = "$politician_name atualizou o perfil.";
    }
    elsif ( $action_name eq 'UPDATED_GREETINGS' ) {
        $ret = "$politician_name atualizou as boas-vindas.";
    }
    elsif ( $action_name eq 'UPDATED_CONTACTS' ) {
        $ret = "$politician_name atualizou os contatos.";
    }
    elsif ( $action_name eq 'UPDATED_ANSWER' ) {
        my $answer      = $self->result_source->schema->resultset('Answer')->find( $self->field_id );
        my $dialog_name = $answer->question->dialog->name;

        $ret = "$politician_name atualizou o diálogo: '$dialog_name'.";
    }
    elsif ( $action_name eq 'UPDATED_KNOWLEDGE_BASE' ) {
        my $knowledge_base      = $self->result_source->schema->resultset('PoliticianKnowledgeBase')->find( $self->field_id );
        my $knowledge_base_type = $knowledge_base->type;

        my $entity         = $knowledge_base->entity_rs->next;
        my $entity_name    = $entity->human_name;

        $ret = "$politician_name atualizou a resposta do tipo '$entity_name' para o tema: '$entity_name'.";
    }
    elsif ( $action_name eq 'CREATED_POLL' ) {
        my $poll          = $self->result_source->schema->resultset('Poll')->find( $self->field_id );
        my $poll_question = $poll->poll_questions->next;
        my $question_name = $poll_question->content;

        $ret = "$politician_name criou a pergunta: '$question_name'.";
    }
    elsif ( $action_name eq 'ACTIVATED_POLL' ) {
        my $poll          = $self->result_source->schema->resultset('Poll')->find( $self->field_id );
        my $poll_question = $poll->poll_questions->next;
        my $question_name = $poll_question->content;

        $ret = "$politician_name ativou a pergunta: '$question_name'.";
    }
    elsif ( $action_name eq 'ANSWERED_ISSUE' ) {
        my $issue          = $self->result_source->schema->resultset('Issue')->find( $self->field_id );
        my $recipient_name = $issue->recipient->name;

        $ret = "$politician_name respondeu a mensagem da(o) seguidora(o): '$recipient_name'.";
    }
    elsif ( $action_name eq 'IGNORED_ISSUE' ) {
        my $issue          = $self->result_source->schema->resultset('Issue')->find( $self->field_id );
        my $recipient_name = $issue->recipient->name;

        $ret = "$politician_name ignorou a mensagem da(o) seguidora(o): '$recipient_name'.";
    }
    elsif ( $action_name eq 'DELETED_ISSUE' ) {
        my $issue          = $self->result_source->schema->resultset('Issue')->find( $self->field_id );
        my $recipient_name = $issue->recipient->name;

        $ret = "$politician_name deletou a mensagem da(o) seguidora(o): '$recipient_name'.";
    }
    elsif ( $action_name eq 'SENT_CAMPAIGN' ) {
        my $campaign      = $self->result_source->schema->resultset('Campaign')->find( $self->field_id );
        my $campaign_type = $campaign->type->human_name;

        $ret = "$politician_name enviou uma campanha do tipo '$campaign_type'.";
    }
	elsif ( $action_name eq 'CREATED_GROUP' ) {
		my $group      = $self->result_source->schema->resultset('Group')->find( $self->field_id );
		my $group_name = $group->name;

        $ret = "$politician_name criou o grupo: '$group_name'.";
	}
	elsif ( $action_name eq 'UPDATED_GROUP' ) {
		my $group      = $self->result_source->schema->resultset('Group')->find( $self->field_id );
		my $group_name = $group->name;

		$ret = "$politician_name atualizou o grupo: '$group_name'.";
	}
	elsif ( $action_name eq 'DELETED_GROUP' ) {
		my $group      = $self->result_source->schema->resultset('Group')->find( $self->field_id );
		my $group_name = $group->name;

		$ret = "$politician_name deletou o grupo: '$group_name'.";
	}

    return $ret;
}

__PACKAGE__->meta->make_immutable;
1;
