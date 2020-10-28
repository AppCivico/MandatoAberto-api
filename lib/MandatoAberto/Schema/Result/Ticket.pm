use utf8;
package MandatoAberto::Schema::Result::Ticket;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Ticket

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

=head1 TABLE: C<ticket>

=cut

__PACKAGE__->table("ticket");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ticket_id_seq'

=head2 organization_chatbot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assignee_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 assigned_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 status

  data_type: 'text'
  is_nullable: 0

=head2 assigned_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 message

  data_type: 'text[]'
  default_value: '{}'::text[]
  is_nullable: 0

=head2 response

  data_type: 'text[]'
  default_value: '{}'::text[]
  is_nullable: 0

=head2 progress_started_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 closed_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 status_last_updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 data

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0

=head2 anonymous

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 organization_ticket_type_id

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
    sequence          => "ticket_id_seq",
  },
  "organization_chatbot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assignee_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "assigned_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "status",
  { data_type => "text", is_nullable => 0 },
  "assigned_at",
  { data_type => "timestamp", is_nullable => 1 },
  "message",
  {
    data_type     => "text[]",
    default_value => \"'{}'::text[]",
    is_nullable   => 0,
  },
  "response",
  {
    data_type     => "text[]",
    default_value => \"'{}'::text[]",
    is_nullable   => 0,
  },
  "progress_started_at",
  { data_type => "timestamp", is_nullable => 1 },
  "closed_at",
  { data_type => "timestamp", is_nullable => 1 },
  "status_last_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "data",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "anonymous",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "organization_ticket_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 assigned_by

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "assigned_by",
  "MandatoAberto::Schema::Result::User",
  { id => "assigned_by" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 assignee

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "assignee",
  "MandatoAberto::Schema::Result::User",
  { id => "assignee_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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

=head2 organization_ticket_type

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::OrganizationTicketType>

=cut

__PACKAGE__->belongs_to(
  "organization_ticket_type",
  "MandatoAberto::Schema::Result::OrganizationTicketType",
  { id => "organization_ticket_type_id" },
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

=head2 ticket_attachments

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketAttachment>

=cut

__PACKAGE__->has_many(
  "ticket_attachments",
  "MandatoAberto::Schema::Result::TicketAttachment",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ticket_logs

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketLog>

=cut

__PACKAGE__->has_many(
  "ticket_logs",
  "MandatoAberto::Schema::Result::TicketLog",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ticket_messages

Type: has_many

Related object: L<MandatoAberto::Schema::Result::TicketMessage>

=cut

__PACKAGE__->has_many(
  "ticket_messages",
  "MandatoAberto::Schema::Result::TicketMessage",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2019-11-13 11:28:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ltrRfnVs2DFIQnhWQA5N6A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->load_components("InflateColumn::Serializer", "Core");
__PACKAGE__->remove_columns(qw/data/);
__PACKAGE__->add_columns(
    data => {
        'data_type'        => "json",
        is_nullable        => 1,
        'serializer_class' => 'JSON'
    },
);

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use JSON;
use WebService::HttpCallback::Async;

use MandatoAberto::Utils;
use MandatoAberto::Mailer::Template;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
    lazy_build => 1,
);

sub _build__httpcb { WebService::HttpCallback::Async->instance }

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                user_id => {
                    required => 0,
                    type     => 'Int'
                },

                assignee_id => {
                    required => 0,
                    type     => 'Int'
                },

                response => {
                    required => 0,
                    type     => 'Str'
                },

                message => {
                    required => 0,
                    type     => 'Str'
                },

                status => {
                    required => 0,
                    type     => 'Str'
                },

                updated_by_chatbot => {
                    required => 1,
                    type     => 'Bool'
                },

                ticket_attachments => {
                    required => 0,
                    type     => 'ArrayRef'
                },
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

            my $log_action_rs = $self->result_source->schema->resultset('TicketLogAction');
            my $actions = {
                'ticket criado'        => 1,
                'ticket designado'     => 2,
                'ticket movido'        => 3,
                'ticket cancelado'     => 4,
                'ticket nova resposta' => 5,
                'ticket nova mensagem' => 6
            };

            my $has_asignee = $self->assignee_id || $values{assignee_id} ? 1 : 0;
            my $assignee;
            if ( $has_asignee ) {
                $assignee = $self->assignee || $self->organization_chatbot->organization->users->search( { user_id => $values{assignee_id} } )->next->user;
                die \['assignee_id', 'invalid'] unless $assignee;
            }

            my $url = $self->organization_chatbot->organization->custom_url ? $self->organization_chatbot->organization->custom_url : $ENV{ASSISTENTE_URL};

            my $ticket;
            $self->result_source->schema->txn_do( sub {
                my $log_action;
                my @logs;

                my @emails;
                my $email_rs = $self->result_source->schema->resultset('EmailQueue');

                my $updated_by_chatbot = delete $values{updated_by_chatbot};

                my $user_id = delete $values{user_id};
                my ($user, $user_name);
                if (!$updated_by_chatbot) {
                    $user = $self->organization_chatbot->organization->users->search( { user_id => $user_id } )->next
                        or die \['user_id', 'invalid'];
                    $user = $user->user;

                    $user_name = $user->name;
                }

                if ( my $status = $values{status} ) {

                    die \['status', 'invalid'] unless $status =~ /^(pending|closed|progress|canceled)$/;
                    $values{status_last_updated_at} = \'NOW()';

                    if ( $status eq 'canceled' ) {
                        push @logs, {
                            text      => "Ticket cancelado pelo usuário",
                            action_id => $actions->{'ticket cancelado'},
                            data => to_json(
                                {
                                    action    => 'ticket cancelado',
                                    status    => 'Cancelado',
                                    impact    => 'neutral',
                                    user_name => $self->recipient->name,
                                }
                            )
                        };
                    }
                    else {
                        my $ticket_rs = $self->result_source->schema->resultset('Ticket');

                        my $current_status = $ticket_rs->human_status($self->status);
                        my $next_status    = $ticket_rs->human_status($status);

                        if ( $current_status ne $next_status ) {
                            my $impact;

                            if ($next_status eq 'Aberto') {
                                $impact = 'negative'
                            }
                            else {
                                $impact = 'positive';
                            }

                            push @logs, {
                                text      => "Ticket movido de '$current_status', para '$next_status', por: $user_name",
                                action_id => $actions->{'ticket movido'},
                                data => to_json(
                                    {
                                        action    => 'ticket movido',
                                        impact    => $impact,
                                        user_name => $user_name,
                                        status    => $next_status
                                    }
                                )
                            };
                        }
                    }

                    # Adicionando email na fila
                    my $email_vars = {
                        ticket_url     => $url . 'chamados/' . $self->id,
                        status         => $status,
                        header_picture => $self->organization_chatbot->organization->email_header
                    };

                    if ($has_asignee) {
                        my $user = $assignee;
                        $email_vars->{name} = $user->name;

                        my $email = MandatoAberto::Mailer::Template->new(
                            to       => $user->email,
                            from     => 'no-reply@assistentecivico.com.br',
                            subject  => 'Ticket atualizado',
                            template => get_data_section('ticket_updated.tt'),
                            vars     => $email_vars,
                        )->build_email();
                        push @emails, { body => $email->as_string } unless $user->email =~ m/email.com/;
                    }
                    else {
                        my $user_rs = $self->organization_chatbot->organization->users;
                        while (my $user_rel = $user_rs->next) {
                            my $user = $user_rel->user;
                            $email_vars->{name} = $user->name;

                            my $email = MandatoAberto::Mailer::Template->new(
                                to       => $user->email,
                                from     => 'no-reply@assistentecivico.com.br',
                                subject  => 'Ticket atualizado',
                                template => get_data_section('ticket_updated.tt'),
                                vars     => $email_vars,
                            )->build_email();
                            push @emails, { body => $email->as_string } unless $user->email =~ m/email.com/;
                        }
                    }

                    $values{closed_at}           = \'NOW()' if $status eq 'closed';
                    $values{progress_started_at} = \'NOW()' if $status eq 'progress';
                }

                if ( my $assignee_id = $values{assignee_id} ) {
                    my $assignee = $self->organization_chatbot->organization->users->search( { user_id => $assignee_id } )->next
                    or die \['assignee_id', 'invalid'];

                    $values{assigned_by} = $user_id or die \['user_id', 'missing'];
                    $values{assigned_at} = \'NOW()';

                    my $assignee_name    = $assignee->user->name;
                    my $assignor_name    = $user->name;
                    my $current_assignee = $self->assignee;

                    if (!$current_assignee || $current_assignee && $current_assignee->name ne $assignee_name) {
                        push @logs, {
                            text      => "Ticket designado para: $assignee_name, por: $assignor_name",
                            action_id => $actions->{'ticket designado'},
                            data => to_json(
                                {
                                    action    => 'ticket designado',
                                    impact    => 'neutral',
                                    user_name => $assignor_name,
                                    status    => $self->status_human_name
                                }
                            )
                        };
                    }
                }

                if ( my $response = $values{response} ) {
                    my $response_param = $values{response};
                    my $responses = $self->response;
                    my $messages  = $self->message;

                    my $messages_size  = scalar @{ $messages };
                    my $responses_size = scalar @{ $responses };

                    if ( $responses_size > $messages_size ) {
                        my $last_response = pop @{$responses};
                        $response         = $last_response . "\n" . $response;
                    }
                    push @{$responses}, $response;

                    my $access_token = $self->organization_chatbot->fb_config->access_token;
                    my $text = 'Você possui uma nova atualização para o seu ticket: #' . $self->id . "\n";
                    $text   .= "Mensagem: $response_param";

                    $self->_httpcb->add(
                        url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                        method  => "post",
                        headers => 'Content-Type: application/json',
                        body    => to_json {
                            messaging_type => "UPDATE",
                            recipient => {
                                id => $self->recipient->fb_id
                            },
                            message => {
                                text          => $text,
                                quick_replies => [
                                    {
                                        content_type => 'text',
                                        title        => 'Voltar ao início',
                                        payload      => 'mainMenu'
                                    },
                                    {
                                        content_type => 'text',
                                        title        => 'Responder',
                                        payload      => 'leaveTMsg' . $self->id
                                    }
                                ]
                            }
                        }
                    );

                    push @logs, {
                            text      => "Ticket atualizado, nova resposta adicionada '$response', por: $user_name",
                            action_id => $actions->{'ticket nova resposta'},
                            data => to_json(
                                {
                                    action    => 'ticket recebeu uma nova resposta',
                                    impact    => 'positive',
                                    user_name => $user_name,
                                    status    => $self->status_human_name
                                }
                            )
                        };

                    $values{response} = $responses;
                    $self->update( { response => [] } );
                }

                if ( my $message = delete $values{message} ) {
                    my $responses = $self->response;
                    my $messages  = $self->message;
                    my $message_param = $message;

                    my $messages_size  = scalar @{ $messages };
                    my $responses_size = scalar @{ $responses };

                    if ( $messages_size > $responses_size ) {
                        my $last_message = pop @{$messages};
                        $message         = $last_message . "\n" . $message;
                    }
                    push @{$messages}, $message;

                    push @logs, {
                            text      => "Ticket atualizado, nova mensagem recebida '$message'",
                            action_id => $actions->{'ticket nova mensagem'},
                            data => to_json(
                                {
                                    action    => 'ticket recebeu uma nova mensagem',
                                    impact    => 'negative',
                                    user_name => $self->recipient->name,
                                    status    => $self->status_human_name
                                }
                            )
                        };

                    # Adicionando email na fila
                    my $email_vars = {
                        ticket_url  => $url . 'chamados/' . $self->id,
                        message     => $message_param
                    };

                    if ($has_asignee) {
                        my $user = $assignee;
                        $email_vars->{name} = $user->name;

                        my $email = MandatoAberto::Mailer::Template->new(
                            to       => $user->email,
                            from     => 'no-reply@assistentecivico.com.br',
                            subject  => 'Ticket atualizado',
                            template => get_data_section('ticket_updated.tt'),
                            vars     => $email_vars,
                        )->build_email();
                        push @emails, { body => $email->as_string } unless $user->email =~ m/email.com/;
                    }
                    else {
                        my $user_rs = $self->organization_chatbot->organization->users;
                        while (my $user_rel = $user_rs->next) {
                            my $user = $user_rel->user;
                            $email_vars->{name} = $user->name;

                            my $email = MandatoAberto::Mailer::Template->new(
                                to       => $user->email,
                                from     => 'no-reply@assistentecivico.com.br',
                                subject  => 'Ticket atualizado',
                                template => get_data_section('ticket_updated.tt'),
                                vars     => $email_vars,
                            )->build_email();
                            push @emails, { body => $email->as_string } unless $user->email =~ m/email.com/;
                        }
                    }

                    $values{message} = $messages;
                    $self->update( { message => [] } );
                }

                if ( my $attachments = delete $values{ticket_attachments} ) {
                    $self->ticket_attachments->populate($attachments);
                }

                $self->ticket_logs->populate(\@logs);
                $email_rs->populate(\@emails);
                $ticket = $self->update(\%values);
            });

            return $ticket;
        }
    };
}

sub build_list {
    my $self = shift;

    return {
        (map { $_ => $self->$_ } qw(id status message response created_at closed_at assigned_at anonymous)),
        (
            logs => [
                map {
                    +{
                        text       => $_->text,
                        created_at => $_->created_at,
                        data       => from_json($_->data)
                    }
                } $self->ticket_logs->search(undef, { order_by => { '-desc' => 'me.created_at' } })->all()
            ]
        ),

        ( $self->anonymous ?
            (
                recipient => {
                    id      => undef,
                    name    => undef,
                    picture => undef
                },
                data => {}
            ) :
            (
                recipient => {
                    id      => $self->recipient->id,
                    name    => $self->recipient->name,
                    picture => $self->recipient->picture
                },
                data => $self->data && $self->data ne "" ? $self->data : {}
            )
        ),

        (
            assignee => {
                id      => $self->assignee ? $self->assignee->id : undef,
                name    => $self->assignee ? $self->assignee->name : undef,
                picture => $self->assignee ? $self->assignee->picture : undef,
            }
        ),

        (
            assignor => {
                id      => $self->assigned_by ? $self->assigned_by->id : undef,
                name    => $self->assigned_by ? $self->assigned_by->name : undef,
                picture => $self->assigned_by ? $self->assigned_by->picture : undef,
            }
        ),

        (
            type => {
                id   => $self->organization_ticket_type_id,
                name => $self->organization_ticket_type->ticket_type->name
            }
        ),

        (
            attachments => [
                map {
                    +{
                        id         => $_->id,
                        type       => $_->type,
                        url        => $_->url,
                        created_at => $_->created_at
                    }
                } $self->ticket_attachments->search( { 'me.attached_to_message' => 0 }, { order_by => { -desc => 'me.created_at' } } )->all()
            ]
        )
    }
}

sub status_human_name {
    my $self = shift;

    my $status = $self->status;
    my $ret;

    if ($status eq 'pending') {
        $ret = 'Aberto'
    }
    elsif ($status eq 'progress') {
        $ret = 'Em andamento'
    }
    elsif ($status eq 'closed') {
        $ret = 'Fechado'
    }
    else {
        $ret = 'Cancelado'
    }

    return $ret;
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ ticket_updated.tt

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
<p style="text-align: center;"><a href="[% home_url %]"><img src="[% header_picture %]" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
<p><b>Ol&#xE1;, [% name %]. </b></p>
<p> <strong> </strong>Um ticket do seu assistente foi atualizado!</p>
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