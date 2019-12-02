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

    $recipient_rs = $recipient_rs->search_rs( { 'me.fb_id' => \'IS NOT NULL' } );

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

    $recipient_rs = $recipient_rs->search_rs( { 'me.fb_id' => \'IS NOT NULL' } );

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

        push @{$attachments}, { name => $name, path => $attachment_file_name, file_name => $attachment_file_name };
    }
    my $message = $self->direct_message->build_message_object();

    my $count = 0;
    while (my $recipient = $recipient_rs->next()) {
        if ($recipient->email) {

            my $email = MandatoAberto::Mailer::Template->new(
                to          => $recipient->email,
                from        => $organization_name . '@appcivico.com',
                subject     => $dm->email_subject,
                template    => get_data_section('email.tt'),
                attachments => $attachments,
                vars        => {
                    organization_name => $organization_name,
                    header            => $organization->email_header,
                    title             => $dm->email_subject,
                    text              => $dm_content,
                    footer            => "<p>Enviado em nome de: $organization_name</p>"
                },
            )->build_email();
            $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
        }


        my $headers = $dm->build_headers( $recipient );

        $self->_httpcb->add(
            url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $organization_chatbot->fb_config->access_token,
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

    close($fh) if $fh;

    $self->update( { count => $count } );

}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ email.tt

<!doctype html><html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"><head><title></title><!--[if !mso]><!-- --><meta http-equiv="X-UA-Compatible" content="IE=edge"><!--<![endif]--><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style type="text/css">#outlook a { padding:0; }
          .ReadMsgBody { width:100%; }
          .ExternalClass { width:100%; }
          .ExternalClass * { line-height:100%; }
          body { margin:0;padding:0;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%; }
          table, td { border-collapse:collapse;mso-table-lspace:0pt;mso-table-rspace:0pt; }
          img { border:0;height:auto;line-height:100%; outline:none;text-decoration:none;-ms-interpolation-mode:bicubic; }
          p { display:block;margin:13px 0; }</style><!--[if !mso]><!--><style type="text/css">@media only screen and (max-width:480px) {
            @-ms-viewport { width:320px; }
            @viewport { width:320px; }
          }</style><!--<![endif]--><!--[if mso]>
        <xml>
        <o:OfficeDocumentSettings>
          <o:AllowPNG/>
          <o:PixelsPerInch>96</o:PixelsPerInch>
        </o:OfficeDocumentSettings>
        </xml>
        <![endif]--><!--[if lte mso 11]>
        <style type="text/css">
          .outlook-group-fix { width:100% !important; }
        </style>
        <![endif]--><!--[if !mso]><!--><link href="https://fonts.googleapis.com/css?family=Open+Sans:300,400,500,700" rel="stylesheet" type="text/css"><style type="text/css">@import url(https://fonts.googleapis.com/css?family=Open+Sans:300,400,500,700);</style><!--<![endif]--><style type="text/css">@media only screen and (min-width:480px) {
        .mj-column-per-100 { width:100% !important; max-width: 100%; }
.mj-column-per-75 { width:75% !important; max-width: 75%; }
      }</style><style type="text/css">@media only screen and (max-width:480px) {
      table.full-width-mobile { width: 100% !important; }
      td.full-width-mobile { width: auto !important; }
    }</style></head><body style="background-color:#ffffff;"><div style="background-color:#ffffff;"><!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--><div style="background:#ffffff;background-color:#ffffff;Margin:0px auto;max-width:600px;"><table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;background-color:#ffffff;width:100%;"><tbody><tr><td style="direction:ltr;font-size:0px;padding:20px 0;padding-bottom:0px;padding-top:0;text-align:center;vertical-align:top;"><!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--><div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"><table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"><tr><td align="center" style="font-size:0px;padding:10px 25px;padding-top:0;padding-right:0px;padding-bottom:0px;padding-left:0px;word-break:break-word;"><table border="0" cellpadding="0" cellspacing="0" role="presentation" style="border-collapse:collapse;border-spacing:0px;"><tbody><tr><td style="width:600px;"><img alt="Header da organização" height="auto" src="[% header %]" style="border:none;display:block;outline:none;text-decoration:none;height:auto;width:100%;" width="600"></td></tr></tbody></table></td></tr></table></div><!--[if mso | IE]></td></tr></table><![endif]--></td></tr></tbody></table></div><!--[if mso | IE]></td></tr></table><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--><div style="Margin:0px auto;max-width:600px;"><table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"><tbody><tr><td style="direction:ltr;font-size:0px;padding:20px 0;padding-bottom:0px;padding-top:0;text-align:center;vertical-align:top;"><!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--><div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"><table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"><tr><td align="left" style="font-size:0px;padding:10px 25px;padding-top:50px;padding-right:25px;padding-bottom:30px;padding-left:25px;word-break:break-word;"><div style="font-family:open Sans Helvetica, Arial, sans-serif;font-size:45px;font-weight:bold;line-height:1;text-align:left;color:#000000;">[% title %]</div></td></tr></table></div><!--[if mso | IE]></td></tr></table><![endif]--></td></tr></tbody></table></div><!--[if mso | IE]></td></tr></table><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--><div style="background:#ffffff;background-color:#ffffff;Margin:0px auto;max-width:600px;"><table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;background-color:#ffffff;width:100%;"><tbody><tr><td style="direction:ltr;font-size:0px;padding:20px 0;padding-bottom:20px;padding-top:20px;text-align:center;vertical-align:top;"><!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:middle;width:600px;" ><![endif]--><div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:middle;width:100%;"><table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:middle;" width="100%"><tr><td align="left" style="font-size:0px;padding:10px 25px;padding-right:25px;padding-left:25px;word-break:break-word;"><div style="font-family:open Sans Helvetica, Arial, sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">[% text %]</div></td></tr><tr><td align="left" style="font-size:0px;padding:10px 25px;padding-right:25px;padding-left:25px;word-break:break-word;"><div style="font-family:open Sans Helvetica, Arial, sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;"><br>[% organization_name %]</div></td></tr></table></div><!--[if mso | IE]></td></tr></table><![endif]--></td></tr></tbody></table></div><!--[if mso | IE]></td></tr></table><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--><div style="Margin:0px auto;max-width:600px;"><table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"><tbody><tr><td style="direction:ltr;font-size:0px;padding:20px 0;text-align:center;vertical-align:top;"><!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:middle;width:450px;" ><![endif]--><div class="mj-column-per-75 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:middle;width:100%;"><table border="0" cellpadding="0" cellspacing="0" role="presentation" style="border-top:1px solid black;vertical-align:middle;" width="100%"><tr><td align="center" style="font-size:0px;padding:10px 25px;padding-right:25px;padding-left:25px;word-break:break-word;"><div style="font-family:open Sans Helvetica, Arial, sans-serif;font-size:10px;line-height:1;text-align:center;color:#000000;">[% footer %]</div></td></tr></table></div><!--[if mso | IE]></td></tr></table><![endif]--></td></tr></tbody></table></div><!--[if mso | IE]></td></tr></table><![endif]--></div></body></html>