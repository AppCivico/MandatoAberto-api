package MandatoAberto::Schema::ResultSet::PrivateReply;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use WebService::HttpCallback::Async;

use JSON::MaybeXS;
use URI::Escape;

use Data::Verifier;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
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

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                item => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $item = $_[0]->get_value('item');

                        die \["item", 'not a Facebook item'] unless $item eq 'post' || $item eq 'comment';
                    }
                },
                post_id => {
                    required => 1,
                    type     => "Str",
                },
                comment_id => {
                    required   => 0,
                    type       => "Str",
                },
                permalink => {
                    required   => 0,
                    type       => "Str",
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

            my $item = $values{item};

            if ($item eq 'comment' && !$values{comment_id}) {
                die \['comment_id', 'missing'];
            }

            my $item_id;
            if ($item eq 'post') {
                $item_id = $values{post_id};

                $self->search(
                    {
                        item    => $item,
                        post_id => $item_id
                    }
                )->count == 1 ? die \['post_id', 'post alredy replied to'] : ()
            } else {
                $item_id = $values{comment_id};

                $self->search( { comment_id => $item_id } )->count == 1 ? die \['comment_id', 'comment alredy replied to'] : ()
            }

            my $politician = $self->result_source->schema->resultset("Politician")->find($values{politician_id});

            my $access_token = $politician->fb_page_access_token;

            my $politician_name = $politician->name;
            my $office_name     = $politician->office->name;
            my $article         = $politician->gender eq 'F' ? 'da' : 'do';

            if ($politician->private_reply_activated) {
                my $message = uri_escape( "Olá sou o Assistente virtual $article $office_name $politician_name. Vi que você comentou em nossa página, você gostaria de enviar uma mensagem, dúvidas, perguntas ou denúncias? Faça isso a qualquer momento que eu entrego para nossa equipe." );

                $self->_httpcb->add(
                    url     => "$ENV{FB_API_URL}/$item_id/private_replies?access_token=$access_token&message=$message",
                    method  => "post",
                );

                $values{reply_sent} = 1;
            }

            my $private_reply = $self->create(\%values);

            return $private_reply;
        }
    };
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

1;