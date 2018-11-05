use utf8;
package MandatoAberto::Schema::Result::PoliticianSummary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianSummary

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

=head1 TABLE: C<politician_summary>

=cut

__PACKAGE__->table("politician_summary");

=head1 ACCESSORS

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 has_active_chatbot

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 recipient_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 campaign_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "has_active_chatbot",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "recipient_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "campaign_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</politician_id>

=back

=cut

__PACKAGE__->set_primary_key("politician_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-16 14:00:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:veOHSUSvUI7dCPrC7/WUkw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
