use utf8;
package MandatoAberto::Schema::Result::Campaign;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Campaign

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

=head1 TABLE: C<campaign>

=cut

__PACKAGE__->table("campaign");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'campaign_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 count

  data_type: 'integer'
  is_nullable: 0

=head2 groups

  data_type: 'integer[]'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "campaign_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "count",
  { data_type => "integer", is_nullable => 0 },
  "groups",
  { data_type => "integer[]", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 direct_message

Type: might_have

Related object: L<MandatoAberto::Schema::Result::DirectMessage>

=cut

__PACKAGE__->might_have(
  "direct_message",
  "MandatoAberto::Schema::Result::DirectMessage",
  { "foreign.campaign_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 poll_propagate

Type: might_have

Related object: L<MandatoAberto::Schema::Result::PollPropagate>

=cut

__PACKAGE__->might_have(
  "poll_propagate",
  "MandatoAberto::Schema::Result::PollPropagate",
  { "foreign.campaign_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::CampaignStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "MandatoAberto::Schema::Result::CampaignStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::CampaignType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "MandatoAberto::Schema::Result::CampaignType",
  { id => "type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-18 11:56:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xLYwssX24otFBmAOu83jcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use WebService::HttpCallback::Async;

use JSON::MaybeXS;

has _httpcb => (
	is         => "ro",
	isa        => "WebService::HttpCallback::Async",
	lazy_build => 1,
);

sub process_and_send {
    my ($self) = @_;

    my @group_ids = @{ $self->groups || [] };

    my $recipient_rs = $self->politician->recipients->only_opt_in->search_by_group_ids(@group_ids)->search(
    	{},
    	{
    		'+select' => [ \"COUNT(1) OVER(PARTITION BY 1)" ],
    		'+as'     => ['total'],
    	}
    );

    my $type_id = $self->type_id;

    # Campanha de mensagem no Facebook
    if ( $type_id == 1 ) {
        $self->send_dm_facebook($recipient_rs);
    }
    else {
        die 'fail while sending campaign';
    }
}

sub send_dm_facebook {
    my ($self, $recipient_rs) = @_;

    my $req = $self->direct_message->build_message_object();

    my $count = 0;
    while (my $recipient = $recipient_rs->next()) {
        # Mando para o httpcallback
        $self->_httpcb->add(
            url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $self->politician->fb_page_access_token,
            method  => "post",
            headers => 'Content-Type: application/json',
            body    => encode_json {
                messaging_type => "UPDATE",
                recipient => {
                    id => $recipient->fb_id
                },
                message => $req
            }
        );

        $count++;
    }
    $self->_httpcb->wait_for_all_responses();

    $self->update( { count => $count } );
}

sub send_email {
    # TODO
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

__PACKAGE__->meta->make_immutable;
1;
