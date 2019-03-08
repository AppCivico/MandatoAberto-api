use utf8;
package MandatoAberto::Schema::Result::UserWithOrganizationData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::UserWithOrganizationData

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<user_with_organization_data>

=cut

__PACKAGE__->table("user_with_organization_data");
__PACKAGE__->result_source_instance->view_definition(" SELECT u.id AS user_id,\n    u.email,\n    o.id AS organization_id,\n    c.id AS chatbot_id\n   FROM (((\"user\" u\n     JOIN user_organization uo ON ((u.id = uo.user_id)))\n     JOIN organization o ON ((o.id = uo.organization_id)))\n     JOIN organization_chatbot c ON ((c.organization_id = o.id)))\n  ORDER BY u.id");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 organization_id

  data_type: 'integer'
  is_nullable: 1

=head2 chatbot_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "organization_id",
  { data_type => "integer", is_nullable => 1 },
  "chatbot_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-02-04 11:10:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xSZu1yK3T/6H7bYPVnfvgA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
