use utf8;
package MandatoAberto::Schema::Result::Movement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Movement

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

=head1 TABLE: C<movement>

=cut

__PACKAGE__->table("movement");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'movement_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "movement_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 movement_discounts

Type: has_many

Related object: L<MandatoAberto::Schema::Result::MovementDiscount>

=cut

__PACKAGE__->has_many(
  "movement_discounts",
  "MandatoAberto::Schema::Result::MovementDiscount",
  { "foreign.movement_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politicians

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->has_many(
  "politicians",
  "MandatoAberto::Schema::Result::Politician",
  { "foreign.movement_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "MandatoAberto::Schema::Result::User",
  { "foreign.movement_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-11-20 19:17:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wqMVeIQPKnK2BTpsciA5ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub get_movement_discount {
    my ($self) = @_;

    my $ret;
    my $movement_discount = $self->movement_discounts->search( { valid_until => 'infinity' } )->next;

    if ( $movement_discount ) {
        my $is_percentage = $movement_discount->percentage ? 1 : 0;
        $ret = {
            has_discount  => 1,
            is_percentage => $is_percentage,
            ( $is_percentage ? ( percentage => $movement_discount->percentage ) : ( amount => $movement_discount->amount ) )
        };
    }
    else {
        $ret = {
            has_discount => 0
        };
    }

    return $ret;
}

sub calculate_discount {
    my ($self) = @_;

    my $discount = $self->get_movement_discount();

    my $value;
    if ( $discount->{is_percentage} ) {
        $value = $ENV{MANDATOABERTO_BASE_AMOUNT} * ( 1 - ( $discount->{percentage} / 100 ) );
    }
    else {
        $value = $ENV{MANDATOABERTO_BASE_AMOUNT} - $discount->{amount};
    }

    return ( $value / 100 );
}

__PACKAGE__->meta->make_immutable;
1;
