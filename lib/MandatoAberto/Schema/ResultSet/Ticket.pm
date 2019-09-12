package MandatoAberto::Schema::ResultSet::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;

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
                    required => 1,
                    type     => "Str"
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

            $self->result_source->schema->resultset('TicketType')->find($values{type_id}) or die \['type_id', 'invalid'];

            my $fb_id     = delete $values{fb_id};
            my $recipient = $self->result_source->schema->resultset('Recipient')->search(
                {
                    organization_chatbot_id => $chatbot->id,
                    fb_id                   => $fb_id
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

            my $ticket;
            $self->result_source->schema->txn_do(sub{

                $ticket = $self->create(\%values);

                my $user_rs = $chatbot->organization->users;
                while (my $user_rel = $user_rs->next) {
                    my $user = $user_rel->user;

                    my $email = MandatoAberto::Mailer::Template->new(
                        to       => $user->email,
                        from     => 'no-reply@assistentecivico.com.br',
                        subject  => "Novo ticket criado",
                        template => get_data_section('ticket_created.tt'),
                        vars     => {
                            name       => $user->name,
                            ticket_url => $ENV{ASSISTENTE_URL} . 'chamados/' . $ticket->id,
                        },
                    )->build_email();

                    $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
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
                    id         => $_->id,
                    message    => $_->message,
                    response   => $_->response,
                    status     => $_->status,
                    created_at => $_->created_at,
                    closed_at  => $_->closed_at,
                    assigned_at => $_->assigned_at,

                    (
                        recipient => {
                            id      => $_->recipient->id,
                            name    => $_->recipient->name,
                            picture => $_->recipient->picture
                        }
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
                            id   => $_->type_id,
                            name => $_->type->name
                        }
                    )
                }
            } $self->search($filter, {page => $page, rows => $rows})->all()
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

    my $avg_close = $ticket_metrics->avg_close ? $ticket_metrics->avg_close : '00:00:00';

    return {
        count           => $self->count,
        description     => 'Aqui você poderá métricas sobre os seus tickets.',
        suggested_actions => [],
        sub_metrics => [
            {
                text              => $count_open . ' tickets em aberto',
                suggested_actions => []
            },
            {
                text              => $count_progress . ' tickets em progresso',
                suggested_actions => []
            },
            {
                text              => $count_closed . ' tickets fechados',
                suggested_actions => []
            },
            {
                text              => 'Tempo de atendimento: ' . $ticket_metrics->avg_open,
                suggested_actions => []
            },
            {
                text              => 'Tempo de resolução: ' . $avg_close,
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
<td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><a href="[% home_url %]"><img src="[% header_picture %]" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
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