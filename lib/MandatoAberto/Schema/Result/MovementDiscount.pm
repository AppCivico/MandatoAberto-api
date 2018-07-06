use utf8;
package MandatoAberto::Schema::Result::MovementDiscount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::MovementDiscount

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

=head1 TABLE: C<movement_discount>

=cut

__PACKAGE__->table("movement_discount");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'movement_discount_id_seq'

=head2 movement_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 percentage

  data_type: 'numeric'
  is_nullable: 1
  size: [5,2]

=head2 amount

  data_type: 'integer'
  is_nullable: 1

=head2 valid_until

  data_type: 'timestamp'
  default_value: infinity
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

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
    sequence          => "movement_discount_id_seq",
  },
  "movement_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "percentage",
  { data_type => "numeric", is_nullable => 1, size => [5, 2] },
  "amount",
  { data_type => "integer", is_nullable => 1 },
  "valid_until",
  { data_type => "timestamp", default_value => "infinity", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
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

=head2 movement

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Movement>

=cut

__PACKAGE__->belongs_to(
  "movement",
  "MandatoAberto::Schema::Result::Movement",
  { id => "movement_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-07-05 01:52:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L46ha0eRZCepdBeMBP7yoA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
