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
                },
                fb_user_id => {
                    required => 1,
                    type     => "Str"
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

            $values{post_id}    = substr $values{post_id},    16 if $values{post_id} && length $values{post_id} > 15;
            $values{comment_id} = substr $values{comment_id}, 16 if $values{comment_id} && length $values{comment_id} > 15;

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

            my $private_reply = $self->create(\%values);
            $private_reply->send();

            return $private_reply;
        }
    };
}

sub get_last_sent_private_reply {
    my ($self, $politician_id, $fb_user_id) = @_;

    my $last_sent_private_reply = $self->result_source->schema->resultset("PrivateReply")->search(
        {
            reply_sent    => 1,
            fb_user_id    => $fb_user_id,
            politician_id => $politician_id
        },
        { order_by => { -desc => 'created_at' } }
    )->first;

    return $last_sent_private_reply;
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

1;