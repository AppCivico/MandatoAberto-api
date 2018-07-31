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
  is_nullable: 1

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
  is_nullable: 1

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'text'
  default_value: 'text'
  is_nullable: 0

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 quick_replies

  data_type: 'json'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 1 },
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
  { data_type => "integer", is_nullable => 1 },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type",
  { data_type => "text", default_value => "text", is_nullable => 0 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 attachment

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::DirectMessageAttachment>

=cut

__PACKAGE__->belongs_to(
  "attachment",
  "MandatoAberto::Schema::Result::DirectMessageAttachment",
  { id => "attachment_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-06-29 19:37:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MFarljvW5axbxAU8/Zhd4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub groups_rs {
    my ($self, $c) = @_;

    return $self->politician->groups->search(
        { 'me.id' => { 'in' => $self->groups || [] } }
    );
}

sub build_message_object {
    my ($self) = @_;

	my $ret;

	if ( $self->type eq 'text' ) {

		$ret = {
			text => $self->content,
			quick_replies => [
				{
					content_type => 'text',
					title        => "Voltar para o início",
					payload      => 'greetings'
				}
			]
		};

	}else {

		# É attachment logo pode ser video, imagem ou template

		if ( $self->attachment_type ne 'template' ) {
			$ret = {
				attachment => {
					type    => $self->attachment_type,
					payload => {
						url         => $self->attachment_url,
						is_reusable => \1
					}
				},
				quick_replies   => [
					{
						content_type => 'text',
						title        => "Voltar para o início",
						payload      => 'greetings'
					}
				]
			  };
		}else {

			# É um template
			$ret = {
				attachment_type => $self->attachment_type,
				template        => $self->template,
				quick_replies   => [
					{
						content_type => 'text',
						title        => "Voltar para o início",
						payload      => 'greetings'
					}
				]
			};
		}

	}

	return $ret;
}

__PACKAGE__->meta->make_immutable;
1;
