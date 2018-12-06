use utf8;
package MandatoAberto::Schema::Result::PollSelfPropagationConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PollSelfPropagationConfig

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

=head1 TABLE: C<poll_self_propagation_config>

=cut

__PACKAGE__->table("poll_self_propagation_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'poll_self_propagation_config_id_seq'

=head2 active

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 send_after

  data_type: 'interval'
  default_value: '02:00:00'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "poll_self_propagation_config_id_seq",
  },
  "active",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "send_after",
  { data_type => "interval", default_value => "02:00:00", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<poll_self_propagation_config_organization_chatbot_id_key>

=over 4

=item * L</organization_chatbot_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "poll_self_propagation_config_organization_chatbot_id_key",
  ["organization_chatbot_id"],
);

=head1 RELATIONS

=head2 organization_chatbot

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbot>

=cut

__PACKAGE__->belongs_to(
  "organization_chatbot",
  "MandatoAberto::Schema::Result::OrganizationChatbot",
  { id => "organization_chatbot_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-12-06 09:23:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/CNzokjqKX2G+oJOHtcvyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
