package MandatoAberto::Schema::ResultSet::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use MandatoAberto::Utils;
use MandatoAberto::Messager::Template;
use WebService::HttpCallback;

use JSON::MaybeXS;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback",
    lazy_build => 1,
);

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search( { user_id => $politician_id } )->count == 1;
                    }
                },
                content => {
                    required   => 1,
                    type       => "Str",
                    max_length => 250,
                },
                name => {
                    required  => 1,
                    type      => "Str",
                    max_length => 50,
                },
                groups => {
                    required   => 0,
                    type       => "ArrayRef[Int]",
                    post_check => sub {
                        my $groups = $_[0]->get_value('groups');

                        for (my $i = 0; $i < @{ $groups }; $i++) {
                            my $group_id = $groups->[$i];

                            my $count = $self->result_source->schema->resultset("Group")->search(
                                {
                                    id            => $group_id,
                                    politician_id => $_[0]->get_value('politician_id')
                                }
                            )->count;
                            die \['groups', "group $group_id does not exists or does not belongs to this politician"] unless $count == 1;
                        }

                        return 1;
                    }
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

            my $politician   = $self->result_source->schema->resultset("Politician")->find($values{politician_id});
            my $access_token = $politician->fb_page_access_token;
            die \['politician_id', 'politician does not have active Facebook page access_token'] if $access_token eq 'undef';

            # Depois de criada a messagem direta, devo adicionar uma entrada
            # na fila para cada recipient atrelado ao rep. público
            # levando em consideração os grupos, se adicionados
            my @group_ids = @{ $values{groups} || [] };
            my $recipient_rs = $politician->recipients->search_by_group_ids(@group_ids);

            my @recipients = $recipient_rs->all;

            my $count = 0;

            for my $recipient (@recipients) {
                # Tratando se o recipient está com opt_in

                # Por enquanto esse tratamento deverá ser feito via uma coluna na própria tabela de recipient
                # my $blacklist_entry = $self->result_source->schema->resultset("BlacklistFacebookMessenger")->search( { recipient_id => $recipient->id } )->next;

                # Mando para o httpcallback
                $self->_httpcb->add(
                    url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                    method  => "post",
                    headers => 'Content-Type: application/json',
                    body    => encode_json {
                        recipient => {
                            id => $recipient->fb_id
                        },
                        message => {
                            text          => $values{content},
                            quick_replies => [
                                {
                                    content_type => 'text',
                                    title        => 'Voltar para o início',
                                    payload      => 'greetings'
                                }
                            ]
                        }
                    }
                ) and $count++ unless !$recipient->fb_opt_in;
            }

            $values{count} = $count;

            my $direct_message = $self->create(\%values);

            return $direct_message;
        }
    };
}

sub _build__httpcb { WebService::HttpCallback->instance }

1;
