use utf8;
package MandatoAberto::Schema::Result::TicketLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::TicketLog

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

=head1 TABLE: C<ticket_log>

=cut

__PACKAGE__->table("ticket_log");

=head1 ACCESSORS

=head2 ticket_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 text

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 action_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 data

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "text",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "action_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "data",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
);

=head1 RELATIONS

=head2 action

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::TicketLogAction>

=cut

__PACKAGE__->belongs_to(
  "action",
  "MandatoAberto::Schema::Result::TicketLogAction",
  { id => "action_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-08-30 11:39:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FmzkB2J7prlGwFx79+w9Ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
