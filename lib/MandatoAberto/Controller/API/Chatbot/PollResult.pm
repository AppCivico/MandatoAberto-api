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

        my $recipient_fb_id = $c->req->params->{fb_id};
        die \["fb_id", "missing"] unless $recipient_fb_id;

        my $recipient = $c->model("DB::Recipient")->search( { fb_id => $recipient_fb_id } )->next;
        die \["fb_id", "could not find recipient with that fb_id"] unless $recipient;

        $params->{recipient_id} = $recipient->id;
        use DDP; p $params;
        return $params;
    },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll-result') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $recipient_fb_id = $c->req->params->{fb_id};
    die \["fb_id", "missing"] unless $recipient_fb_id;

    my $poll_id = $c->req->params->{poll_id};
    die \["poll_id", "missing"] unless $poll_id;

    my $recipient_answer = $c->stash->{collection}->search(
        {
            'recipient.fb_id' => $recipient_fb_id,
            'poll.id'       => $poll_id
        },
        { prefetch => [ 'poll_question_option', { 'poll_question_option' => { 'poll_question' => 'poll' } }, 'recipient' ] }
    )->count;

    return $self->status_ok(
        $c,
        entity => {
            recipient_answered => $recipient_answer,
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;
