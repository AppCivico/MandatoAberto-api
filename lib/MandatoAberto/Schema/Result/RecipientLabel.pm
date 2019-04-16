use utf8;
package MandatoAberto::Schema::Result::RecipientLabel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::RecipientLabel

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

=head1 TABLE: C<recipient_label>

=cut

__PACKAGE__->table("recipient_label");

=head1 ACCESSORS

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 label_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "label_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<recipient_label_recipient_id_label_id_key>

=over 4

=item * L</recipient_id>

=item * L</label_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "recipient_label_recipient_id_label_id_key",
  ["recipient_id", "label_id"],
);

=head1 RELATIONS

=head2 label

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Label>

=cut

__PACKAGE__->belongs_to(
  "label",
  "MandatoAberto::Schema::Result::Label",
  { id => "label_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 recipient

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "MandatoAberto::Schema::Result::Recipient",
  { id => "recipient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-04-12 10:16:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5hx9D1ltBIJMabsHLFmw+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
