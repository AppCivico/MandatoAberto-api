use utf8;
package MandatoAberto::Schema::Result::Organization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Organization

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

=head1 TABLE: C<organization>

=cut

__PACKAGE__->table("organization");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organization_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 premium

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 premium_updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 approved

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 approved_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 is_mandatoaberto

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 picture

  data_type: 'text'
  is_nullable: 1

=head2 invite_token

  data_type: 'uuid'
  default_value: uuid_generate_v4()
  is_nullable: 0
  size: 16

=head2 menu_config

  data_type: 'json'
  is_nullable: 1

=head2 custom_url

  data_type: 'text'
  is_nullable: 1

=head2 email_header

  data_type: 'text'
  is_nullable: 1

=head2 has_ticket

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 has_email_broadcast

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 fb_app_id

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organization_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "premium",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "premium_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "approved",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "approved_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "is_mandatoaberto",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "picture",
  { data_type => "text", is_nullable => 1 },
  "invite_token",
  {
    data_type => "uuid",
    default_value => \"uuid_generate_v4()",
    is_nullable => 0,
    size => 16,
  },
  "menu_config",
  { data_type => "json", is_nullable => 1 },
  "custom_url",
  { data_type => "text", is_nullable => 1 },
  "email_header",
  { data_type => "text", is_nullable => 1 },
  "has_ticket",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "has_email_broadcast",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "fb_app_id",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization_chatbots

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbot>

=cut

__PACKAGE__->has_many(
  "organization_chatbots",
  "MandatoAberto::Schema::Result::OrganizationChatbot",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_dialogs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationDialog>

=cut

__PACKAGE__->has_many(
  "organization_dialogs",
  "MandatoAberto::Schema::Result::OrganizationDialog",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_modules

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationModule>

=cut

__PACKAGE__->has_many(
  "organization_modules",
  "MandatoAberto::Schema::Result::OrganizationModule",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organization_ticket_types

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationTicketType>

=cut

__PACKAGE__->has_many(
  "organization_ticket_types",
  "MandatoAberto::Schema::Result::OrganizationTicketType",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_organizations

Type: has_many

Related object: L<MandatoAberto::Schema::Result::UserOrganization>

=cut

__PACKAGE__->has_many(
  "user_organizations",
  "MandatoAberto::Schema::Result::UserOrganization",
  { "foreign.organization_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-11-14 10:18:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LqKJIIPDuobIr9Ip9O//qw


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
                custom_url => {
                    required => 0,
                    type     => 'Str'
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

            return $self->update(\%values);
        }
    };
}


sub chatbot {
    my ($self) = @_;

    return $self->chatbots->next;
}

sub chatbots {
    my ($self) = @_;

    return $self->organization_chatbots;
}

sub users {
    my ($self) = @_;

    return $self->user_organizations;
}

sub user {
    my ($self) = @_;

    return $self->users->next->user;
}

sub chatbots_for_get {
    my ($self) = @_;

    return [
        map {
            +{
                id                   => $_->id,
                name                 => $_->name,
                picture              => $_->picture,
                use_dialogflow       => $_->general_config->use_dialogflow,
                dialogflow_config_id => $_->general_config->dialogflow_config_id,
                fb_page_id           => $_->has_fb_config ? $_->fb_config->page_id : undef,
                fb_access_token      => $_->has_fb_config ? $_->fb_config->access_token : undef,
            }
        } $self->organization_chatbots->all
    ]
}

sub weight_for_module {
    my ($self, %opts) = @_;

    die 'missing id'            unless $opts{module_id} || $opts{sub_module_id};
    die 'must send only one id' if     $opts{module_id} && $opts{sub_module_id};

    my ($rs, $id);
    if ( $opts{module_id} ) {
        $rs = $self->result_source->schema->resultset('Module');
        $id = $opts{module_id};
    }
    else {
        $rs = $self->result_source->schema->resultset('SubModule');
        $id = $opts{sub_module_id};
    }

    my ($config, $weight);
    if ($self->menu_config) {
        $config = from_json( $self->menu_config );
    }

    my $module = $rs->find($id);

    if ( $config ) {

    }
    else {
        $weight = $module->standard_weight;
    }

    return $weight;
}

__PACKAGE__->meta->make_immutable;
1;
