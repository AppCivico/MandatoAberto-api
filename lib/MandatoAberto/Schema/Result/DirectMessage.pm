use utf8;
package MandatoAberto::Schema::Result::DirectMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::DirectMessage

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

=head1 TABLE: C<direct_message>

=cut

__PACKAGE__->table("direct_message");

=head1 ACCESSORS

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 0

=head2 sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 groups

  data_type: 'integer[]'
  is_nullable: 1

=head2 count

  data_type: 'integer'
  is_nullable: 0

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'text'
  default_value: 'text'
  is_nullable: 0

=head2 attachment_type

  data_type: 'text'
  is_nullable: 1

=head2 attachment_template

  data_type: 'text'
  is_nullable: 1

=head2 attachment_url

  data_type: 'text'
  is_nullable: 1

=head2 quick_replies

  data_type: 'json'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "groups",
  { data_type => "integer[]", is_nullable => 1 },
  "count",
  { data_type => "integer", is_nullable => 0 },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type",
  { data_type => "text", default_value => "text", is_nullable => 0 },
  "attachment_type",
  { data_type => "text", is_nullable => 1 },
  "attachment_template",
  { data_type => "text", is_nullable => 1 },
  "attachment_url",
  { data_type => "text", is_nullable => 1 },
  "quick_replies",
  { data_type => "json", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</campaign_id>

=back

=cut

__PACKAGE__->set_primary_key("campaign_id");

=head1 RELATIONS

=head2 campaign

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Campaign>

=cut

__PACKAGE__->belongs_to(
  "campaign",
  "MandatoAberto::Schema::Result::Campaign",
  { id => "campaign_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-06-17 17:15:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P5XfoSbuM9Ml0/sPKgpSlw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub groups_rs {
    my ($self, $c) = @_;

    return $self->politician->groups->search(
        { 'me.id' => { 'in' => $self->groups || [] } }
    );
}

__PACKAGE__->meta->make_immutable;
1;
