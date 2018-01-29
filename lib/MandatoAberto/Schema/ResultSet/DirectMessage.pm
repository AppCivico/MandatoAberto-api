package MandatoAberto::Schema::ResultSet::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { $ENV{FB_API_URL} or die "missing env 'FB_API_URL'." }

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

            my $furl = Furl->new();

            my $politician   = $self->result_source->schema->resultset("Politician")->find($values{politician_id});
            my $access_token = $politician->fb_page_access_token;
            die \['politician_id', 'politician does not have active Facebook page access_token'] if $access_token eq 'undef';

            # Depois de criada a messagem direta, devo adicionar uma entrada
            # na fila para cada recipient atrelado ao rep. público
            my $recipient_rs = $self->result_source->schema->resultset("Recipient");
            for my $group_id ( @{ $values{groups} } ) {
                use DDP; p $group_id;
                $recipient_rs = $recipient_rs->search_by_group_id($group_id);
                # use DDP; p $recipient_rs->as_query;
            }
            use DDP; p $recipient_rs->as_query();
            my $v = $recipient_rs->all; p $v;
            my @recipients = $self->result_source->schema->resultset("Recipient")->search(
                {
                    politician_id => $values{politician_id},
                    # groups        => []
                },
                { column        => [ qw(me.fb_id) ]  }
            )->all();

            $values{count} = scalar @recipients; 
            my $direct_message = $self->create(\%values);

            foreach (@recipients) {
                my $recipient = $_;

                # Mando para o httpcallback
                $self->_httpcb->send_message(
                    url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token,
                    method  => "post",
                    headers => [ 'Content-Type:application/json' ],
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
                );
            }

            return $direct_message;
        }
    };
}

sub _build__httpcb { WebService::HttpCallback->instance }

1;
