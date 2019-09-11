use utf8;
package MandatoAberto::Schema::Result::TicketLogAction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::TicketLogAction

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

=head1 TABLE: C<ticket_log_action>

=cut

__PACKAGE__->table("ticket_log_action");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 code

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "code",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<ticket_log_action_code_key>

=over 4

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint("ticket_log_action_code_key", ["code"]);

=head1 RELATIONS

=head2 ticket_logs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketLog>

=cut

__PACKAGE__->has_many(
  "ticket_logs",
  "MandatoAberto::Schema::Result::TicketLog",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-08-30 11:00:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RzyaZGo+MyO8/Pqgf37sHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
