use utf8;
package MandatoAberto::Schema::Result::ChatbotStep;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::ChatbotStep

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

=head1 TABLE: C<chatbot_steps>

=cut

__PACKAGE__->table("chatbot_steps");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'chatbot_steps_id_seq'

=head2 payload

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chatbot_steps_id_seq",
  },
  "payload",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<chatbot_steps_human_name_key>

=over 4

=item * L</human_name>

=back

=cut

__PACKAGE__->add_unique_constraint("chatbot_steps_human_name_key", ["human_name"]);

=head2 C<chatbot_steps_payload_key>

=over 4

=item * L</payload>

=back

=cut

__PACKAGE__->add_unique_constraint("chatbot_steps_payload_key", ["payload"]);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-04 13:18:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o5T1fMpPyRo3zqLQ8yiZ1A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
