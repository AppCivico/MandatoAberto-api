use utf8;
package MandatoAberto::Schema::Result::PollPropagate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PollPropagate

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

=head1 TABLE: C<poll_propagate>

=cut

__PACKAGE__->table("poll_propagate");

=head1 ACCESSORS

=head2 poll_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 groups

  data_type: 'integer[]'
  is_nullable: 1

=head2 count

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "poll_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "groups",
  { data_type => "integer[]", is_nullable => 1 },
  "count",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</campaign_id>

=back

=cut

__PACKAGE__->set_primary_key("campaign_id");

=head1 RELATIONS

=head2 campaign

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Campaign>

=cut

__PACKAGE__->belongs_to(
  "campaign",
  "MandatoAberto::Schema::Result::Campaign",
  { id => "campaign_id" },
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

=head2 poll

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Poll>

=cut

__PACKAGE__->belongs_to(
  "poll",
  "MandatoAberto::Schema::Result::Poll",
  { id => "poll_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-02-22 14:07:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uqYI25cRR9/yt+NpmrurMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
