use utf8;
package MandatoAberto::Schema::Result::DirectMessageAttachment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::DirectMessageAttachment

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

=head1 TABLE: C<direct_message_attachment>

=cut

__PACKAGE__->table("direct_message_attachment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'direct_message_attachment_id_seq'

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 template

  data_type: 'text'
  is_nullable: 1

=head2 url

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "direct_message_attachment_id_seq",
  },
  "type",
  { data_type => "text", is_nullable => 0 },
  "template",
  { data_type => "text", is_nullable => 1 },
  "url",
  { data_type => "text", is_nullable => 1 },
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
  { "foreign.attachment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-06-29 19:34:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OjtkvDKfK3lw3fbj99JSmw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
