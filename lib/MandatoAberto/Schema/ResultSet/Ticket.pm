package MandatoAberto::Schema::ResultSet::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;
use utf8;

use Encode qw(encode);

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use JSON;

use MandatoAberto::Utils;
use MandatoAberto::Mailer::Template;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 0,
                    type       => "Int"
                },
                chatbot_id => {
                    required => 0,
                    type     => 'Int'
                },
                fb_id => {
                    required => 0,
                    type     => "Str"
                },
                recipient_id => {
                    required => 0,
                    type     => 'Int'
                },
                type_id => {
                    required => 1,
                    type     => 'Int'
                },
                message => {
                    required => 0,
                    type     => "ArrayRef",
                },
                data => {
                    required => 0,
                    type     => 'Str'
                },
                anonymous => {
                    required => 0,
                    type     => 'Bool'
                },
                ticket_attachments => {
                    required => 0,
                    type     => 'ArrayRef'
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my $chatbot;
            if (my $organization_chatbot_id = delete $values{chatbot_id}) {
                $chatbot = $self->result_source->schema->resultset('OrganizationChatbot')->find($organization_chatbot_id)
                  or die \['organization_chatbot_id', 'invalid'];
            }
            elsif (my $politician_id = delete $values{politician_id}) {
                my $politician = $self->result_source->schema->resultset('Politician')->find($politician_id)
                  or die \['politician_id', 'invalid'];

                $chatbot = $politician->user->organization->chatbot;
            }
            else {
                die \['chatbot_id', 'missing'];
            }

            # my $type = $self->result_source->schema->resultset('TicketType')->find($values{type_id}) or die \['type_id', 'invalid'];
            # delete $values{type_id};

            my $organization_ticket_type = $self->result_source->schema->resultset('OrganizationTicketType')->search( { id => $values{type_id}, organization_id => $chatbot->organization->id } )->next
                or die \['type_id', 'invalid'];
            $values{organization_ticket_type_id} = $organization_ticket_type->id;

            my $type = $organization_ticket_type->ticket_type;
            delete $values{type_id};

            if ($values{anonymous}) {
                $values{anonymous} = 0 if !$type->can_be_anonymous;
            }

            my $fb_id        = delete $values{fb_id};
            my $recipient_id = delete $values{recipient_id};

            if (!$fb_id && !$recipient_id) {
                die \['recipient_id', 'missing'];
            }

            my $recipient = $self->result_source->schema->resultset('Recipient')->search(
                {
                    organization_chatbot_id => $chatbot->id,

                    # recipient_id tomará precedência.
                    (
                        $recipient_id ? ( id => $recipient_id ) : ( fb_id => $fb_id )
                    )
                }
            )->next or die \['fb_id', 'invalid'];

            my $log_action = $self->result_source->schema->resultset('TicketLogAction')->search( { 'me.code' => 'ticket criado' } )->next;

            $values{organization_chatbot_id} = $chatbot->id;
            $values{recipient_id}            = $recipient->id;
            $values{status}                  = 'pending';
            $values{ticket_logs}             = [
                {
                    text      => 'Ticket criado',
                    action_id => $log_action->id,
                    data      => to_json(
                        {
                            status    => 'Aberto',
                            action    => 'Ticket criado',
                            impact    => 'neutral',
                        }
                    )
                }
            ];

            # Preparando messages
            # if (my $messages = $values{message}) {
            #     use DDP; p $messages;
            # }

            if (my $attachments = delete $values{attachments}) {
                $values{ticket_attachments} = $attachments;
            }

            eval {
                decode_json($values{data})
            };

            $values{data} = {} if $@;

            my $ticket;
            $self->result_source->schema->txn_do(sub{
                my $organization = $chatbot->organization;
                my $user_rs      = $chatbot->organization->users;

                $ticket = $self->create(\%values);

                if (my $send_email_to = $organization_ticket_type->send_email_to) {
                    my $user = $user_rs->search( { 'user.email' => $send_email_to }, { join => 'user' } )->next;

                    my $email = MandatoAberto::Mailer::Template->new(
                        to       => $send_email_to,
                        from     => 'no-reply@appcivico.com',
                        subject  => "Novo ticket criado",
                        template => get_data_section('ticket_created.tt'),
                        vars     => {
                            name         => $user ? $user->user->name : $send_email_to,
                            ticket_url   => $ENV{SQITCH_DEPLOY} eq 'prod' ? ('https://dipiou.appcivico.com/chamados/' . $ticket->id) : ('https://dev.dipiou.appcivico.com/chamados/' . $ticket->id),
                            email_header => $ticket->organization_chatbot->organization->email_header
                        },
                    )->build_email();
                    $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });

                    if ($user) {
                        $ticket->update(
                            {
                                assignee_id => $user->user->id,
                                assigned_at => \'NOW()'
                            }
                        );
                    }
                }
                else {
                    while (my $user_rel = $user_rs->next) {
                        my $user = $user_rel->user;
                        next unless $user->email eq 'edgard.lobo@appcivico.com';

                        my $email = MandatoAberto::Mailer::Template->new(
                            to       => $user->email,
                            from     => 'no-reply@appcivico.com',
                            subject  => "Novo ticket criado",
                            template => get_data_section('ticket_created.tt'),
                            vars     => {
                                name       => $user->name,
                                ticket_url => $organization->custom_url . 'chamados/' . $ticket->id,
                                email_header => $ticket->organization_chatbot->organization->email_header
                            },
                        )->build_email();

                        $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });

                    }
                }

                # Caso o recipient seja WEB, ou seja, sem fb_id e com uuid.
                # Envio e-mail para o endereço cadastrado no ticket.
                if (!$ticket->recipient->fb_id && $ticket->data->{mail}) {

                    my $email = MandatoAberto::Mailer::Template->new(
                        to       => $ticket->data->{mail},
                        from     => 'no-reply@appcivico.com',
                        subject  => "Novo ticket criado",
                        template => get_data_section('ticket_created_web.tt'),
                        vars     => {
                            ticket_id    => $ticket->id,
                            email_header => $ticket->organization_chatbot->organization->email_header
                        },
                    )->build_email();

                    $email = Encode::encode('utf-8',$email->as_string);

                    $self->result_source->schema->resultset('EmailQueue')->create({ body => $email });
                }
            });

            return $ticket;
        }
    };
}

sub build_list {
    my ($self, $page, $rows, $filter) = @_;

    $page = 1  if !defined $page;
    $rows = 20 if !defined $rows;

    if ( $filter ) {
        die \['filter', 'invalid'] unless $filter =~ m/pending|closed|progress|canceled|all/;

        if ($filter eq 'pending') {
            $filter = { 'me.status' => 'pending' }
        }
        elsif ($filter eq 'closed') {
            $filter = { 'me.status' => 'closed' }
        }
        elsif ($filter eq 'progress') {
            $filter = { 'me.status' => 'progress' }
        }
        elsif ($filter eq 'all') {
            $filter = undef;
        }
        else {
            $filter = { 'me.status' => 'canceled' }
        }

        $self = $self->search_rs($filter);
    }

    return {
        tickets => [
            map {
                +{
                    id          => $_->id,
                    message     => $_->message,
                    response    => $_->response,
                    status      => $_->status,
                    created_at  => $_->created_at,
                    closed_at   => $_->closed_at,
                    assigned_at => $_->assigned_at,
                    anonymous   => $_->anonymous,

                    ( $_->anonymous ?
                        (
                            recipient => {
                                id      => undef,
                                name    => undef,
                                picture => undef
                            }
                        ) :
                        (
                            recipient => {
                                id      => $_->recipient->id,
                                picture => $_->recipient->picture,

                                # Caso o recipient seja criado através de um chatbot da Web, seu nome é seu uuid
                                # Para não ficar estranho na visualização, será enviado um nome mas informativo.
                                name => $_->recipient->name =~ /browser/ ? 'Sem nome (ticket criado através de um chatbot WEB)' : $_->recipient->name
                            }
                        )
                    ),

                    (
                        assignee => {
                            id      => $_->assignee_id ? $_->assignee->id : undef,
                            name    => $_->assignee_id ? $_->assignee->name : undef,
                            picture => $_->assignee_id ? $_->assignee->picture : undef
                        }
                    ),

                    (
                        assignor => {
                            id      => $_->assigned_by ? $_->assigned_by->id : undef,
                            name    => $_->assigned_by ? $_->assigned_by->name : undef,
                            picture => $_->assigned_by ? $_->assigned_by->picture : undef
                        }
                    ),

                    (
                        type => {
                            id   => $_->organization_ticket_type_id,
                            name => $_->organization_ticket_type->ticket_type->name
                        }
                    )
                }
            } $self->search($filter, {page => $page, rows => $rows, order_by => { -desc => 'me.created_at' } })->all()
        ],
        itens_count => $self->count
    }
}

sub human_status {
    my ($self, $status) = @_;

    if ($status eq 'pending') {
        $status = 'Aberto';
    }
    elsif ($status eq 'closed') {
        $status = 'Fechado';
    }
    else {
        $status = 'Em andamento';
    }

    return $status;
}

sub extract_metrics {
    my ($self, %opts) = @_;

    my $count_open     = $self->search({'me.status' => 'pending'})->count;
    my $count_progress = $self->search({'me.status' => 'progress'})->count;
    my $count_closed   = $self->search({'me.status' => 'closed'})->count;

    my $politician     = $self->result_source->schema->resultset('Politician')->find($opts{politician_id});
    my $chatbot_id     = $politician->user->organization_chatbot->id;
    my $ticket_metrics = $self->result_source->schema->resultset('ViewTicketMetrics')->search( undef, { bind => [ $chatbot_id, $chatbot_id ] } )->next;

    my $avg_close = $ticket_metrics->avg_close ? $ticket_metrics->avg_close : '0';
    my $avg_open  = $ticket_metrics->avg_open ? $ticket_metrics->avg_open : '0';

    return {
        count           => $self->count,
        description     => 'Aqui você poderá métricas sobre os seus tickets.',
        suggested_actions => [],
        sub_metrics => [
            {
                text              => 'Tempo de atendimento: ' . $avg_open . ' minutos',
                suggested_actions => []
            },
            {
                text              => 'Tempo de resolução: ' . $avg_close . ' minutos',
                suggested_actions => []
            }
        ]
    }
}

1;

__DATA__

@@ ticket_created.tt

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
<p><b>Olá, [% name %]. </b></p>
<p> <strong> </strong>Seu assistente recebeu um novo ticket!</p>
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
<td align="center" valign="middle"><a href="[% ticket_url %]" target="_blank" class="x_btn" style="background:#276165; border-radius:8px; color:#ffffff; font-family:'Montserrat',Arial,sans-serif; font-size:15px; padding:16px 24px 15px 24px; text-decoration:none; text-transform:uppercase"><strong>VER TICKET</strong></a></td>
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

@@ ticket_created_web.tt

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
<p style="text-align: center;"><img src="https://i.imgur.com/curitaU.png" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></p>
<br>
<p><b>Ol&#xE1;!</b></p>
<p><b>Seu ticket foi criado!</b></p>
<p>Seu ticket foi criado com sucesso, o número dele é: #[% ticket_id %].</p>
<p>Utilize este número para alterar, ou consultar, seu ticket no chatbot.</p>
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