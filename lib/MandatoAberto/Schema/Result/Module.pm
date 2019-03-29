use utf8;
package MandatoAberto::Schema::Result::Module;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Module

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

=head1 TABLE: C<module>

=cut

__PACKAGE__->table("module");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 human_name

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 standard_weight

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "human_name",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "standard_weight",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<module_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("module_name_key", ["name"]);

=head2 C<module_standard_weight_key>

=over 4

=item * L</standard_weight>

=back

=cut

__PACKAGE__->add_unique_constraint("module_standard_weight_key", ["standard_weight"]);

=head1 RELATIONS

=head2 organization_modules

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationModule>

=cut

__PACKAGE__->has_many(
  "organization_modules",
  "MandatoAberto::Schema::Result::OrganizationModule",
  { "foreign.module_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sub_modules

Type: has_many

Related object: L<MandatoAberto::Schema::Result::SubModule>

=cut

__PACKAGE__->has_many(
  "sub_modules",
  "MandatoAberto::Schema::Result::SubModule",
  { "foreign.module_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-03-28 11:40:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iVg5rybiGfKuuRj5A0fA8Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub has_sub_modules {
    my ($self) = @_;

    return $self->sub_modules->search()->next ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
1;
