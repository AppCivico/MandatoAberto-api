package MandatoAberto::Controller::API::Poll::Question;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollQuestion",
    no_user => 1,

    # AutoResultPUT.
    object_key => "poll_questions",

    # AutoResultGET
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{poll_id} = $c->stash->{poll}->id;

        return $params;
    },
);

sub root : Chained('/api/poll/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('question') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $question_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $question_id } );

    my $question = $c->stash->{collection}->find($question_id);
    $c->detach("/error_404") unless ref $question;
    $c->stash->{poll_questions} = $question;

    my $poll = $c->model("DB::Poll")->search( { id => $question->poll_id } )->next;
    $c->detach("/error_404") unless ref $poll;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;