use utf8;
package MandatoAberto::Schema::Result::TicketAttachment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::TicketAttachment

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

=head1 TABLE: C<ticket_attachment>

=cut

__PACKAGE__->table("ticket_attachment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ticket_attachment_id_seq'

=head2 ticket_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 ticket_message_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 attached_to_message

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 url

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
    sequence          => "ticket_attachment_id_seq",
  },
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "ticket_message_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attached_to_message",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "url",
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

=head1 RELATIONS

=head2 ticket

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Ticket>

=cut

__PACKAGE__->belongs_to(
  "ticket",
  "MandatoAberto::Schema::Result::Ticket",
  { id => "ticket_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 ticket_message

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::TicketMessage>

=cut

__PACKAGE__->belongs_to(
  "ticket_message",
  "MandatoAberto::Schema::Result::TicketMessage",
  { id => "ticket_message_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-10-18 13:36:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dQde02bSJRJH8zYq53qbFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
