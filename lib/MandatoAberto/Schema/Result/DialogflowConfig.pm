use utf8;
package MandatoAberto::Schema::Result::DialogflowConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::DialogflowConfig

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

=head1 TABLE: C<dialogflow_config>

=cut

__PACKAGE__->table("dialogflow_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'dialogflow_config_id_seq'

=head2 project_id

  data_type: 'text'
  is_nullable: 0

=head2 credentials

  data_type: 'json'
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
    sequence          => "dialogflow_config_id_seq",
  },
  "project_id",
  { data_type => "text", is_nullable => 0 },
  "credentials",
  { data_type => "json", is_nullable => 0 },
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

=head2 C<dialogflow_config_project_id_key>

=over 4

=item * L</project_id>

=back

=cut

__PACKAGE__->add_unique_constraint("dialogflow_config_project_id_key", ["project_id"]);

=head1 RELATIONS

=head2 organization_chatbot_general_configs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::OrganizationChatbotGeneralConfig>

=cut

__PACKAGE__->has_many(
  "organization_chatbot_general_configs",
  "MandatoAberto::Schema::Result::OrganizationChatbotGeneralConfig",
  { "foreign.dialogflow_config_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-02-04 10:28:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:acfLp381G5gTvKZIdZnCMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub chatbots_using {
    my ($self) = @_;

    return $self->organization_chatbot_general_configs->search( undef, { prefetch => 'organization_chatbot' } )
}

__PACKAGE__->meta->make_immutable;
1;
