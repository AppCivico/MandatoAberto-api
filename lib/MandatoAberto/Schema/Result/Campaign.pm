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

=head2 status_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 count

  data_type: 'integer'
  is_nullable: 0

=head2 groups

  data_type: 'integer[]'
  is_nullable: 1

=head2 err_reason

  data_type: 'text'
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
  "status_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "count",
  { data_type => "integer", is_nullable => 0 },
  "groups",
  { data_type => "integer[]", is_nullable => 1 },
  "err_reason",
  { data_type => "text", is_nullable => 1 },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-12-02 16:57:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:444Z5+BDrSbdKrFtTrK83g


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use WebService::HttpCallback::Async;

use JSON;
use MandatoAberto::Utils;

use IO::Handle;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
    lazy_build => 1,
);

sub process_and_send {
    my ($self, $logger) = @_;

    my @group_ids = @{ $self->groups || [] };

    my $recipient_rs = $self->organization_chatbot->recipients->only_opt_in->search_by_group_ids(@group_ids)->search(
        {},
        {
            '+select' => [ \"COUNT(1) OVER(PARTITION BY 1)" ],
            '+as'     => ['total'],
        }
    );

    $logger->info(sprintf("Número de contatos que receberão a campanha: '%d'.", $recipient_rs->count)) if $logger;

    my $type_id = $self->type_id;

    # Campanha de mensagem no Facebook
    if ( $type_id == 1 ) {
        $self->send_dm_facebook($recipient_rs, $logger);
    }
    elsif ( $type_id == 2 ) {
        $self->send_poll_facebook($recipient_rs, $logger)
    }
    elsif ( $type_id == 3 ) {
        $self->send_email($recipient_rs, $logger);
    }
    else {
        die 'fail while sending campaign';
    }
}

sub send_dm_facebook {
    my ($self, $recipient_rs, $logger) = @_;

    my $message = $self->direct_message->build_message_object();
    $logger->info("Message object:" . to_json $message) if $logger;

    my $count = 0;
    while (my $recipient = $recipient_rs->next()) {
        my $headers = $self->direct_message->build_headers( $recipient );

        # Mando para o httpcallback
        $self->_httpcb->add(
            url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $self->organization_chatbot->fb_config->access_token,
            method  => "post",
            headers => $headers,
            body    => to_json {
                messaging_type => "UPDATE",
                recipient => {
                    id => $recipient->fb_id
                },
                message => $message
            }
        );

        $count++;
    }
    $self->_httpcb->wait_for_all_responses();

    $self->update( { count => $count } );
}

sub send_poll_facebook {
    my ($self, $recipient_rs, $logger) = @_;

    my $poll = $self->poll_propagate->poll or die 'no such poll object';

    my $poll_question_option_rs = $self->result_source->schema->resultset("PollQuestionOption");
    my @poll_question_options   = $poll_question_option_rs->search(
        { 'poll.id' => $poll->id },
        { prefetch => [ 'poll_question' , { 'poll_question' => "poll" } ] }
    )->all();

    my $question      = $poll_question_options[0]->poll_question->content;
    my $first_option  = $poll_question_options[0];
    my $second_option = $poll_question_options[1];

    my $count = 0;
    while (my $recipient = $recipient_rs->next()) {
        # Mando para o httpcallback
        $self->_httpcb->add(
            url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $self->organization_chatbot->fb_config->access_token,
            method  => "post",
            headers => 'Content-Type: application/json',
            body    => to_json {
                messaging_type => "UPDATE",
                recipient => {
                    id => $recipient->fb_id
                },
                message => {
                    text          => $question,
                    quick_replies => [
                        {
                            content_type => 'text',
                            title        => $first_option->content,
                            payload      => 'pollAnswerPropagate_' . $first_option->id
                        },
                        {
                            content_type => 'text',
                            title        => $second_option->content,
                            payload      => 'pollAnswerPropagate_' . $second_option->id
                        },
                    ]
                }
            }
        );

        $count++;
    }
    $self->_httpcb->wait_for_all_responses();

    $self->update( { count => $count } );
}

sub send_email {
    my ($self, $recipient_rs, $logger) = @_;

    my $dm         = $self->direct_message;
    my $dm_content = $dm->content;
    $dm_content    =~ s/\n/<br>/gm;

    my $organization_chatbot = $self->organization_chatbot;
    my $organization         = $organization_chatbot->organization;

    my $organization_name = $organization_chatbot->organization->name;
    $organization_name    =~ s/\s//g;

    my $attachments = [];
    my $fh;
    if (my $attachment_file_name = $dm->email_attachment_file_name) {
        my ($path) = $attachment_file_name =~ /^\/.+\//g;
        my $name   = substr $attachment_file_name, length $path, length $attachment_file_name;

        push @{$attachments}, { name => $name, path => $path, file_name => $attachment_file_name };
    }

    my $count = 0;
    while (my $recipient = $recipient_rs->next()) {
        my $email = MandatoAberto::Mailer::Template->new(
            to          => $recipient->email,
            from        => $organization_name . '@assistente.appcivico.com',
            subject     => $dm->email_subject,
            template    => get_data_section('email.tt'),
            attachments => $attachments,
            vars        => {
                organization_name   => $organization_name,
                organization_header => $organization->email_header
                recipient_name      => $recipient->name,
                text                => $dm_content,
            },
        )->build_email();

        $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });

        $count++;
    }

    close($fh) if $fh;

    $self->update( { count => $count } );

}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ email.tt

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html charset=UTF-8">
</head>
<body>
<div leftmargin="0" marginheight="0" marginwidth="0" topmargin="0" style="background-color:#f5f5f5; font-family:'Montserrat',Arial,sans-serif; margin:0; padding:0; width:100%">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse">
<tbody>
<tr>
<td>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="600" style="border-collapse:collapse">
<tbody>
<tr>
<td height="50"></td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" style="background-color:rgb(255,255,255); border-radius:0 0 7px 7px; font-family:'Montserrat',Arial,sans-serif; font-size:13px; font-weight:normal; line-height:24px; padding:30px 0; text-align:center; vertical-align:top">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="84%" style="border-collapse:collapse">
<tbody>
<tr>
<td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><img src="[% organization_header %]" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></p>
<p><b>Olá, [% recipient_name %]. </b></p>
<p> [% text %] </p>
  </td>
</tr>
<tr>
<td height="30"></td>
</tr>
<tr>
<td align="center" bgcolor="#ffffff" valign="top" style="padding-top:20px">
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate; border-radius:7px; margin:0">
<tbody>
<tr>
<td align="center" valign="middle"><a href="[% ticket_url %]" target="_blank" class="x_btn" style="background:#502489; border-radius:8px; color:#ffffff; font-family:'Montserrat',Arial,sans-serif; font-size:15px; padding:16px 24px 15px 24px; text-decoration:none; text-transform:uppercase"><strong>VER TICKET</strong></a></td>
</tr>
</tbody>
</table>
</td>
</tr>
<tr>
<td height="40"></td>
</tr>

<tr>
<td height="30"></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="540" style="border-collapse:collapse">
  <tbody>
<tr>
<td align="center" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:11px; font-weight:300; line-height:16px; margin:0; padding:30px 0px">

</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>

</div>
</div></div>