package MandatoAberto::Controller::API::Politician::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::DirectMessage",

    list_key  => "direct_messages",
    build_row => sub {
        return { $_[0]->get_columns() };
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

sub list_POST {
    my ($self, $c) = @_;

    die \['premium', 'politician is not premium'] unless $c->stash->{politician}->premium;

    my $groups;
    if ($c->req->params->{groups}) {
        $c->req->params->{groups} =~ s/(\[|\]|(\s))//g;

        my @groups = split(',', $c->req->params->{groups});

        $groups = \@groups;
    } else {
        $groups = [];
    }

    my $direct_message = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            politician_id => $c->stash->{politician}->id,
            groups        => $groups,
            content       => $c->req->params->{content},
            name          => $c->req->params->{name},
        },
    );

    my $politician_name = $c->stash->{politician}->name;

    $c->slack_notify("O usuário ${\($politician_name)} disparou uma campanha para ${\($direct_message->count)} recipiente(s)") unless is_test();

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Politician::DirectMessage")->action_for('result'), [ $direct_message->id ]),
        entity   => { id => $direct_message->id }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 1000;

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
