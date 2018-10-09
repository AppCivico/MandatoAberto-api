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
  is_nullable: 0

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
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-04 16:46:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3XC2JhCKZXFZQHnWhC0guA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub description {
    my ($self) = @_;

    my $action_name    = $self->action->name;
    my $recipient_name = $self->recipient->name;

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

    return $ret;
}

__PACKAGE__->meta->make_immutable;
1;
