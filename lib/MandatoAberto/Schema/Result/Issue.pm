use utf8;
package MandatoAberto::Schema::Result::Issue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Issue

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

=head1 TABLE: C<issue>

=cut

__PACKAGE__->table("issue");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'issue_id_seq'

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 message

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

=head2 reply

  data_type: 'text'
  is_nullable: 1

=head2 entities

  data_type: 'integer[]'
  is_nullable: 1

=head2 peding_entity_recognition

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 saved_attachment_id

  data_type: 'text'
  is_nullable: 1

=head2 saved_attachment_type

  data_type: 'text'
  is_nullable: 1

=head2 deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 read

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

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
    sequence          => "issue_id_seq",
  },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "message",
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
  "reply",
  { data_type => "text", is_nullable => 1 },
  "entities",
  { data_type => "integer[]", is_nullable => 1 },
  "peding_entity_recognition",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "saved_attachment_id",
  { data_type => "text", is_nullable => 1 },
  "saved_attachment_type",
  { data_type => "text", is_nullable => 1 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "read",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
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

=head2 recipient

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "MandatoAberto::Schema::Result::Recipient",
  { id => "recipient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-04-10 15:42:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ym9P/jxnxTCu5h8nY9YRQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use MandatoAberto::Utils;
use WebService::HttpCallback::Async;

use JSON;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
    lazy_build => 1,
);

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                reply => {
                    required   => 0,
                    type       => "Str",
                    max_length => 2000
                },
                groups => {
                    required   => 0,
                    type       => "ArrayRef[Int]",
                    post_check => sub {
                        my $groups     = $_[0]->get_value('groups');

                        for (my $i = 0; $i < @{ $groups }; $i++) {
                            my $group_id = $groups->[$i];

                            my $group = $self->result_source->schema->resultset("Group")->search(
                                {
                                   'me.id'                      => $group_id,
                                   'me.organization_chatbot_id' => $self->organization_chatbot_id,
                                }
                            )->next;

                            die \['groups', "group $group_id does not exists or does not belongs to this politician"] unless ref $group;
                            die \['groups', "group $group_id isn't ready"] unless $group->get_column('status') eq 'ready';
                        }

                        return 1;
                    }
                },
                saved_attachment_id => {
                    required => 0,
                    type     => 'Str'
                },
                saved_attachment_type => {
                    required => 0,
                    type     => 'Str'
                },
                deleted => {
                    required => 0,
                    type     => 'Bool'
                },
                read => {
                    required => 0,
                    type     => 'Bool'
                }
            }
        )
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            # Tratando caso de apenas abrir e ler a mensagem
            if ( defined $values{read} ) {

                return $self->update( { read => $values{read} } );
            }

            die \['organization_chatbot_id', 'Não há um chatbot ativo para responder essa mensagem'] unless $self->organization_chatbot->has_access_token;
            my $access_token = $self->organization_chatbot->fb_config->access_token;
            my $recipient    = $self->recipient;

            # Adicionando recipient à um grupo
            if ($values{groups}) {
                my @group_ids = @{ $values{groups} || [] };

                for my $group_id (@group_ids) {
                    $recipient->add_to_group($group_id);
                }

                delete $values{groups};
            }

            if ($self->recipient->fb_id) {
                if ($values{reply}) {
                    my $message;
                    # Tratando se a mensagem tem mais de 100 chars
                    if (length $self->message > 100) {
                        $message = substr $self->message, 0, 97;
                        $message = $message . "...";
                    }
                    else {
                        $message = $self->message;
                    }

                    $self->_httpcb->add(
                        url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                        method  => "post",
                        headers => 'Content-Type: application/json',
                        body    => to_json {
                            messaging_type => "UPDATE",
                            recipient => {
                                id => $recipient->fb_id
                            },
                            message => {
                                text          => "Voc\ê enviou: " . $message . "\n\nResposta: " . $values{reply},
                                quick_replies => [
                                    {
                                        content_type => 'text',
                                        title        => 'Voltar ao início',
                                        payload      => 'mainMenu'
                                    }
                                ]
                            }
                        }
                    );
                }
                elsif ( $values{saved_attachment_id} ) {
                    my $message;
                    # Tratando se a mensagem tem mais de 100 chars
                    if (length $self->message > 100) {
                        $message = substr $self->message, 0, 97;
                        $message = $message . "...";
                    }
                    else {
                        $message = $self->message;
                    }

                    $self->_httpcb->add(
                        url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                        method  => "post",
                        headers => 'Content-Type: application/json',
                        body    => to_json {
                            messaging_type => "UPDATE",
                            recipient => {
                                id => $recipient->fb_id
                            },
                            message => {
                                text          => "Voc\ê enviou: " . $message,
                                quick_replies => [
                                    {
                                        content_type => 'text',
                                        title        => 'Voltar ao início',
                                        payload      => 'mainMenu'
                                    }
                                ]
                            }
                        }
                    );

                    $self->_httpcb->add(
                        url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                        method  => "post",
                        headers => 'Content-Type: application/json',
                        body    => to_json {
                            messaging_type => "UPDATE",
                            recipient => {
                                id => $recipient->fb_id
                            },
                            message => {
                                attachment => {
                                    type    => $values{saved_attachment_type},
                                    payload => {
                                        attachment_id => $values{saved_attachment_id}
                                    }
                                },
                                quick_replies => [
                                    {
                                        content_type => 'text',
                                        title        => 'Voltar ao início',
                                        payload      => 'mainMenu'
                                    }
                                ]
                            }
                        }
                    );
                }

                $self->_httpcb->wait_for_all_responses();
            }
            else {
                die \['attachment', 'not-allowed'] if $values{saved_attachment_id};

                if ($self->recipient->uuid && $self->recipient->email && $values{reply}) {
                    my $email = MandatoAberto::Mailer::Template->new(
                        to       => $self->recipient->email,
                        from     => 'no-reply@appcivico.com',
                        subject  => "Resposta para o seu chamado",
                        template => get_data_section('issue_reply_web.tt'),
                        vars     => {
                            message => $self->message,
                            reply   => $values{reply},
                            email_header => $self->organization_chatbot->organization->email_header
                        },
                    )->build_email();

                    $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
                }
            }

            $self->update({
                %values,
                updated_at => \'NOW()',
            });
        }
    };
}

sub entity_rs {
    my ($self) = @_;

    return $self->organization_chatbot->politician_entities->search(
        {
            'me.id' => { 'in' => $self->entities ? $self->entities : 0 },
        }
    );
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ issue_reply_web.tt

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
<td align="center" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><a href="[% home_url %]"><img src="[% email_header %]" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
<br>
<p><b>Olá!</b></p>
<p>Seu chamado recebeu uma resposta!</p>
<p>Você enviou: [% message %]</p>
<p>Resposta: [% reply %]</p>
  </td>
</tr>
<tr>
<td height="30"></td>
</tr>
<tr>
<td align="center" bgcolor="#ffffff" valign="top" style="padding-top:20px">
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate; border-radius:7px; margin:0">
<tbody>
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
