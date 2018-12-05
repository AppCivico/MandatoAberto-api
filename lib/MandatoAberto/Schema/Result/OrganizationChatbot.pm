use utf8;
package MandatoAberto::Schema::Result::OrganizationChatbot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::OrganizationChatbot

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

=head1 TABLE: C<organization_chatbot>

=cut

__PACKAGE__->table("organization_chatbot");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organization_chatbot_id_seq'

=head2 chatbot_platform_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 organization_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 picture

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organization_chatbot_id_seq",
  },
  "chatbot_platform_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "organization_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "picture",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 answers

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Answer>

=cut

__PACKAGE__->has_many(
  "answers",
  "MandatoAberto::Schema::Result::Answer",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 campaigns

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Campaign>

=cut

__PACKAGE__->has_many(
  "campaigns",
  "MandatoAberto::Schema::Result::Campaign",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chatbot_platform

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::ChatbotPlatform>

=cut

__PACKAGE__->belongs_to(
  "chatbot_platform",
  "MandatoAberto::Schema::Result::ChatbotPlatform",
  { id => "chatbot_platform_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 groups

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Group>

=cut

__PACKAGE__->has_many(
  "groups",
  "MandatoAberto::Schema::Result::Group",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issues",
  "MandatoAberto::Schema::Result::Issue",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Organization>

=cut

__PACKAGE__->belongs_to(
  "organization",
  "MandatoAberto::Schema::Result::Organization",
  { id => "organization_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 organization_chatbot_facebook_config

Type: might_have

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbotFacebookConfig>

=cut

__PACKAGE__->might_have(
  "organization_chatbot_facebook_config",
  "MandatoAberto::Schema::Result::OrganizationChatbotFacebookConfig",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_chatbot_general_config

Type: might_have

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbotGeneralConfig>

=cut

__PACKAGE__->might_have(
  "organization_chatbot_general_config",
  "MandatoAberto::Schema::Result::OrganizationChatbotGeneralConfig",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_chatbot_personae

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbotPersona>

=cut

__PACKAGE__->has_many(
  "organization_chatbot_personae",
  "MandatoAberto::Schema::Result::OrganizationChatbotPersona",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_chatbot_twitter_config

Type: might_have

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbotTwitterConfig>

=cut

__PACKAGE__->might_have(
  "organization_chatbot_twitter_config",
  "MandatoAberto::Schema::Result::OrganizationChatbotTwitterConfig",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politician_entities

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianEntity>

=cut

__PACKAGE__->has_many(
  "politician_entities",
  "MandatoAberto::Schema::Result::PoliticianEntity",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politician_knowledge_bases

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianKnowledgeBase>

=cut

__PACKAGE__->has_many(
  "politician_knowledge_bases",
  "MandatoAberto::Schema::Result::PoliticianKnowledgeBase",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 polls

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Poll>

=cut

__PACKAGE__->has_many(
  "polls",
  "MandatoAberto::Schema::Result::Poll",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 recipients

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->has_many(
  "recipients",
  "MandatoAberto::Schema::Result::Recipient",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-12-05 11:04:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G/w3Q8BplZet70sviU3vNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub create_persona {
    my ($self, %opts) = @_;


}

sub general_config {
    my ($self) = @_;

    return $self->organization_chatbot_general_config;
}

sub fb_config {
    my ($self) = @_;

    return $self->organization_chatbot_facebook_config;
}

__PACKAGE__->meta->make_immutable;
1;
