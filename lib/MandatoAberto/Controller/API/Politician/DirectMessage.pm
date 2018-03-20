package MandatoAberto::Controller::API::Politician::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::DirectMessage",

    list_key  => "direct_messages",
    build_row => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        die \['premium', 'politician is not premium'] unless $c->stash->{politician}->premium;

        $params->{politician_id} = $c->user->id;

        if ($c->req->params->{groups}) {
            $c->req->params->{groups} =~ s/(\[|\]|(\s))//g;

            my @groups = split(',', $c->req->params->{groups});

            $params->{groups} = \@groups;
        } else {
            $params->{groups} = [];
        }

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('direct-message') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    return $self->status_ok(
        $c,
        entity => {
            direct_messages => [
                map {
                    my $dm = $_;

                    +{
                        campaign_id => $dm->get_column('campaign_id'),
                        content     => $dm->get_column('content'),
                        sent        => $dm->get_column('sent'),
                        created_at  => $dm->get_column('created_at'),
                        name        => $dm->get_column('name'),
                        count       => $dm->get_column('count'),
                        groups      => [
                            map {
                                my $g = $_;

                                {
                                    id   => $g->get_column('id'),
                                    name => $g->get_column('name')
                                }
                            } $dm->groups_rs->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { politician_id => $politician_id },
                    {
                        page => $page,
                        rows => $results
                    }
                )->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
