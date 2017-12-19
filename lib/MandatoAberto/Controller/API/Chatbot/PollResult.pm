package MandatoAberto::Controller::API::Chatbot::PollResult;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollResult",
    no_user => 1,

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $citizen_fb_id = $c->req->params->{fb_id};
        die \["fb_id", "missing"] unless $citizen_fb_id;

        my $citizen = $c->model("DB::Citizen")->search( { fb_id => $citizen_fb_id } )->next;
        die \["fb_id", "could not find citizen with that fb_id"] unless $citizen;

        $params->{citizen_id} = $citizen->id;

        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll-result') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $citizen_fb_id = $c->req->params->{fb_id};
    die \["fb_id", "missing"] unless $citizen_fb_id;

    my $poll_id = $c->req->params->{poll_id};
    die \["poll_id", "missing"] unless $poll_id;

    my $citizen_answer = $c->stash->{collection}->search(
        {
            'citizen.fb_id' => $citizen_fb_id,
            'poll.id'       => $poll_id
        },
        { prefetch => [ 'option', { 'option' => { 'question' => 'poll' } }, 'citizen' ] }
    )->count;

    return $self->status_ok(
        $c,
        entity => {
            citizen_answered => $citizen_answer,
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;