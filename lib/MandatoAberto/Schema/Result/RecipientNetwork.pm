use utf8;
package MandatoAberto::Schema::Result::RecipientNetwork;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::RecipientNetwork

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

=head1 TABLE: C<recipient_network>

=cut

__PACKAGE__->table("recipient_network");

=head1 ACCESSORS

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 followers_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 friends_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "followers_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "friends_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "updated_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</recipient_id>

=back

=cut

__PACKAGE__->set_primary_key("recipient_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-07-20 11:40:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pJaFp0O/7ua0mC5X3cjmfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
