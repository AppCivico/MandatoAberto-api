use utf8;
package MandatoAberto::Schema::Result::Politian;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Politian

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

=head1 TABLE: C<politian>

=cut

__PACKAGE__->table("politian");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politian_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 address_state

  data_type: 'text'
  is_nullable: 0

=head2 address_city

  data_type: 'text'
  is_nullable: 0

=head2 party_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 office_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 fb_page_id

  data_type: 'text'
  is_nullable: 1

=head2 fb_app_id

  data_type: 'text'
  is_nullable: 1

=head2 fb_app_secret

  data_type: 'text'
  is_nullable: 1

=head2 fb_page_acess_token

  data_type: 'text'
  is_nullable: 1

=head2 approved

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 approved_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politian_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "address_state",
  { data_type => "text", is_nullable => 0 },
  "address_city",
  { data_type => "text", is_nullable => 0 },
  "party_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "office_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "fb_page_id",
  { data_type => "text", is_nullable => 1 },
  "fb_app_id",
  { data_type => "text", is_nullable => 1 },
  "fb_app_secret",
  { data_type => "text", is_nullable => 1 },
  "fb_page_acess_token",
  { data_type => "text", is_nullable => 1 },
  "approved",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "approved_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 office

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Office>

=cut

__PACKAGE__->belongs_to(
  "office",
  "MandatoAberto::Schema::Result::Office",
  { id => "office_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 party

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Party>

=cut

__PACKAGE__->belongs_to(
  "party",
  "MandatoAberto::Schema::Result::Party",
  { id => "party_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "MandatoAberto::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-19 16:46:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L91M+3Ncs1kCOdAFReGL9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
