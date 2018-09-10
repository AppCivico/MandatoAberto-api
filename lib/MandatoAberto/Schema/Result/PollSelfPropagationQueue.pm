use utf8;
package MandatoAberto::Schema::Result::PollSelfPropagationQueue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PollSelfPropagationQueue

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

=head1 TABLE: C<poll_self_propagation_queue>

=cut

__PACKAGE__->table("poll_self_propagation_queue");

=head1 ACCESSORS

=head2 poll_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 sent_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "poll_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "sent_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-09-10 13:31:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ji2L4+MmoF80HTEtVLfBbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
