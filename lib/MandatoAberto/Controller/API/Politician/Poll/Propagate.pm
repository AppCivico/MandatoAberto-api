package MandatoAberto::Controller::API::Politician::Poll::Propagate;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollPropagate",

    # AutoListGET
    list_key => "poll_propagate",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        die \['premium', 'politician is not premium'] unless $c->stash->{politician}->premium;

        $params->{politician_id} = $c->user->id;
        $params->{poll_id}       = $c->stash->{poll}->id;

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

sub root : Chained('/api/politician/poll/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('propagate') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET { }

__PACKAGE__->meta->make_immutable;

1;