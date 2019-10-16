use utf8;
package MandatoAberto::Schema::Result::TicketMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::TicketMessage

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

=head1 TABLE: C<ticket_message>

=cut

__PACKAGE__->table("ticket_message");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ticket_message_id_seq'

=head2 ticket_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 text

  data_type: 'text'
  is_nullable: 0

=head2 created_by_recipient

  data_type: 'boolean'
  default_value: true
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
    sequence          => "ticket_message_id_seq",
  },
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "text",
  { data_type => "text", is_nullable => 0 },
  "created_by_recipient",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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

=head1 RELATIONS

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

=head2 ticket

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Ticket>

=cut

__PACKAGE__->belongs_to(
  "ticket",
  "MandatoAberto::Schema::Result::Ticket",
  { id => "ticket_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ticket_attachments

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketAttachment>

=cut

__PACKAGE__->has_many(
  "ticket_attachments",
  "MandatoAberto::Schema::Result::TicketAttachment",
  { "foreign.ticket_message_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "MandatoAberto::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-10-16 07:30:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XLi4mJFzs5PfiRjO94nNPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
