use utf8;
package MandatoAberto::Schema::Result::Office;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Office

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

=head1 TABLE: C<office>

=cut

__PACKAGE__->table("office");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'office_id_seq'

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
    sequence          => "office_id_seq",
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

=head1 UNIQUE CONSTRAINTS

=head2 C<office_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("office_name_key", ["name"]);

=head1 RELATIONS

=head2 politicians

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->has_many(
  "politicians",
  "MandatoAberto::Schema::Result::Politician",
  { "foreign.office_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-25 17:13:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fD17avv7cdkpBxY4B9qirA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
