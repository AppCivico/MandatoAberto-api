use utf8;
package MandatoAberto::Schema::Result::OrganizationChatbotTwitterConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::OrganizationChatbotTwitterConfig

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

=head1 TABLE: C<organization_chatbot_twitter_config>

=cut

__PACKAGE__->table("organization_chatbot_twitter_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organization_chatbot_twitter_config_id_seq'

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 twitter_id

  data_type: 'text'
  is_nullable: 0

=head2 oauth_token

  data_type: 'text'
  is_nullable: 0

=head2 token_secret

  data_type: 'text'
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
    sequence          => "organization_chatbot_twitter_config_id_seq",
  },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "twitter_id",
  { data_type => "text", is_nullable => 0 },
  "oauth_token",
  { data_type => "text", is_nullable => 0 },
  "token_secret",
  { data_type => "text", is_nullable => 0 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<organization_chatbot_twitter_config_organization_chatbot_id_key>

=over 4

=item * L</organization_chatbot_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "organization_chatbot_twitter_config_organization_chatbot_id_key",
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-11-20 19:17:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3waySjcWeZUOH1j468Ukzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
