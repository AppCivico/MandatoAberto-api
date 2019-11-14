use utf8;
package MandatoAberto::Schema::Result::OrganizationTicketType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::OrganizationTicketType

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

=head1 TABLE: C<organization_ticket_type>

=cut

__PACKAGE__->table("organization_ticket_type");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organization_ticket_type_id_seq'

=head2 organization_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ticket_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 can_be_anonymous

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 send_email_to

  data_type: 'text'
  is_nullable: 1

=head2 usual_response_interval

  data_type: 'interval'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organization_ticket_type_id_seq",
  },
  "organization_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ticket_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "can_be_anonymous",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "send_email_to",
  { data_type => "text", is_nullable => 1 },
  "usual_response_interval",
  { data_type => "interval", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Organization>

=cut

__PACKAGE__->belongs_to(
  "organization",
  "MandatoAberto::Schema::Result::Organization",
  { id => "organization_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ticket_type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::TicketType>

=cut

__PACKAGE__->belongs_to(
  "ticket_type",
  "MandatoAberto::Schema::Result::TicketType",
  { id => "ticket_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 tickets

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Ticket>

=cut

__PACKAGE__->has_many(
  "tickets",
  "MandatoAberto::Schema::Result::Ticket",
  { "foreign.organization_ticket_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-11-14 12:07:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WWAhzznw0WqcSkvaq1Xm7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
