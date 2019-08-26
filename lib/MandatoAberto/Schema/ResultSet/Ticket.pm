package MandatoAberto::Schema::ResultSet::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;

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

            $values{organization_chatbot_id} = $chatbot->id;
            $values{recipient_id}            = $recipient->id;
            $values{status}                  = 'pending';
            $values{ticket_logs}             = [ { text => 'Ticket criado' } ];

            my $ticket;
            $self->result_source->schema->txn_do(sub{

                $ticket = $self->create(\%values);
            });

            return $ticket;
        }
    };
}

sub build_list {
    my ($self, $page, $rows) = @_;

    $page = 1  if !defined $page;
    $rows = 20 if !defined $rows;

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
                            id   => $_->recipient->id,
                            name => $_->recipient->name,
                        }
                    ),

                    (
                        assignee => {
                            id   => $_->assignee ? $self->assignee->id : undef,
                            name => $_->assignee ? $self->assignee->name : undef
                        }
                    ),

                    (
                        assignor => {
                            id   => $_->assigned_by ? $self->assigned_by->id : undef,
                            name => $_->assigned_by ? $self->assigned_by->name : undef
                        }
                    )
                }
            } $self->search(undef, {page => $page, rows => $rows})->all()
        ],
        itens_count => $self->count
    }
}

sub human_status {
    my ($self, $status) = @_;

    if ($status eq 'pending') {
        $status = 'pendente';
    }
    elsif ($status eq 'closed') {
        $status = 'fechado';
    }
    else {
        $status = 'em progresso';
    }

    return $status;
}

1;
