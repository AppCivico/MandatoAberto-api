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
  default_value: 1
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
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
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

=head2 labels

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Label>

=cut

__PACKAGE__->has_many(
  "labels",
  "MandatoAberto::Schema::Result::Label",
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

=head2 politician_contacts

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianContact>

=cut

__PACKAGE__->has_many(
  "politician_contacts",
  "MandatoAberto::Schema::Result::PoliticianContact",
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

=head2 politician_private_reply_configs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianPrivateReplyConfig>

=cut

__PACKAGE__->has_many(
  "politician_private_reply_configs",
  "MandatoAberto::Schema::Result::PoliticianPrivateReplyConfig",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politicians_greeting

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianGreeting>

=cut

__PACKAGE__->has_many(
  "politicians_greeting",
  "MandatoAberto::Schema::Result::PoliticianGreeting",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_self_propagation_configs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollSelfPropagationConfig>

=cut

__PACKAGE__->has_many(
  "poll_self_propagation_configs",
  "MandatoAberto::Schema::Result::PollSelfPropagationConfig",
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

=head2 private_replies

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PrivateReply>

=cut

__PACKAGE__->has_many(
  "private_replies",
  "MandatoAberto::Schema::Result::PrivateReply",
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

=head2 tickets

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Ticket>

=cut

__PACKAGE__->has_many(
  "tickets",
  "MandatoAberto::Schema::Result::Ticket",
  { "foreign.organization_chatbot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-08-20 14:02:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Js3OwMbneJQHoFzspM+pqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use JSON;

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name => {
                    required => 0,
                    type     => 'Str'
                },
                picture => {
                    required => 0,
                    type     => 'Str'
                },
                page_id => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $page_id = $_[0]->get_value('page_id');

                        $self->result_source->schema->resultset('OrganizationChatbotFacebookConfig')->search(
                            {
                                organization_chatbot_id => { '!=' => $self->id },
                                page_id                 => $page_id
                            }
                        )->count and die \['page_id', 'invalid'];

                        return 1;
                    }
                },
                access_token => {
                    required => 0,
                    type     => 'Str',
                    post_check => sub {
                        my $access_token = $_[0]->get_value('access_token');

                        $self->result_source->schema->resultset('OrganizationChatbotFacebookConfig')->search(
                            {
                                organization_chatbot_id => { '!=' => $self->id },
                                access_token            => $access_token
                            }
                        )->count and die \['access_token', 'invalid'];

                        return 1;
                    }
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $chatbot;
            $self->result_source->schema->txn_do(sub {
                # Caso mande page_id e access_token devo atualizar ou criar a configuração do facebook
                if ( $values{page_id} && $values{access_token} ) {
                    $self->result_source->schema->resultset('OrganizationChatbotFacebookConfig')->find_or_create(
                        {
                            organization_chatbot_id => $self->id,
                            page_id                 => $values{page_id},
                            access_token            => $values{access_token}
                        },
                        { key => 'organization_chatbot_facebook_confi_organization_chatbot_id_key' }
                    );

                    delete $values{$_} for qw( page_id access_token );
                }

                $chatbot = $self->update(\%values);
            });

            return $chatbot;
        }
    };
}

sub general_config {
    my ($self) = @_;

    return $self->organization_chatbot_general_config;
}

sub fb_config {
    my ($self) = @_;

    return $self->organization_chatbot_facebook_config;
}

sub fb_config_for_GET {
    my ($self) = @_;

    my $config = $self->fb_config;

    return {
        access_token => $config ? $config->access_token : undef ,
        page_id      => $config ? $config->page_id      : undef
    }
}

sub politician_private_reply_config {
    my ($self) = @_;

    return $self->politician_private_reply_configs->next;
}

sub poll_self_propagation_config {
    my ($self) = @_;

    return $self->poll_self_propagation_configs->next;
}

sub has_access_token {
    my ($self) = @_;

    my $has_config = $self->fb_config ? 1 : 0;

    my $ret;
    if ( $has_config && $self->fb_config->access_token ) {
        $ret = 1;
    }
    else {
        $ret = 0;
    }

    return $ret;
}

sub sync_dialogflow {
    my ($self, $c) = @_;

    my $has_general_config = $self->general_config ? 1 : 0;

    return 0 unless $self->general_config->dialogflow_config_id;

    return $self->politician_entities->sync_dialogflow_one_chatbot( $self->id );
}

sub has_fb_config {
    my ($self) = @_;

    return $self->fb_config ? 1 : 0;
}

sub has_group_for_label {
    my ($self, $label_id) = @_;

    return $self->groups->search( { '-and' => [ \"filter->'rules'->0->>'name' = 'LABEL_IS'", \"filter->'rules'->0->'data'->>'value' = '$label_id'",  ] } )->count > 0 ? 1 : 0;
}

sub upsert_groups_for_labels {
    my ($self) = @_;

    my $labels = $self->labels;

    while ( my $label = $labels->next() ) {
        next if $self->has_group_for_label($label->id);

        my $group = $self->groups->create(
            {
                name   => $label->name,
                status => 'processing',
                filter => to_json(
                    {
                        operator => 'AND',
                        rules => [
                            {
                                name => 'LABEL_IS',
                                data => { value => $label->id },
                            },
                        ],
                    }
                ),
            }
        );
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
