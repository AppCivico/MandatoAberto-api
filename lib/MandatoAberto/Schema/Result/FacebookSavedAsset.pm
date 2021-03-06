use utf8;
package MandatoAberto::Schema::Result::FacebookSavedAsset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::FacebookSavedAsset

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

=head1 TABLE: C<facebook_saved_asset>

=cut

__PACKAGE__->table("facebook_saved_asset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'facebook_saved_asset_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 fb_asset_id

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
    sequence          => "facebook_saved_asset_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "fb_asset_id",
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

=head2 direct_messages

Type: has_many

Related object: L<MandatoAberto::Schema::Result::DirectMessage>

=cut

__PACKAGE__->has_many(
  "direct_messages",
  "MandatoAberto::Schema::Result::DirectMessage",
  { "foreign.facebook_saved_asset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issues",
  "MandatoAberto::Schema::Result::Issue",
  { "foreign.facebook_saved_asset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 politician_knowledge_bases

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianKnowledgeBase>

=cut

__PACKAGE__->has_many(
  "politician_knowledge_bases",
  "MandatoAberto::Schema::Result::PoliticianKnowledgeBase",
  { "foreign.facebook_saved_asset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-08-24 17:26:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m1tRyG5RKSm9bhb6GZubJw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
