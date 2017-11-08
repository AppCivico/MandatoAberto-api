package MandatoAberto::Controller::API::PollQuestion;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollQuestion",

    # AutoResultPUT.
    object_key     => "poll_questions",
    result_put_for => "update",

    # AutoListGET
    list_key => "poll_questions",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll-questions') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_question_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_question_id } );

    my $poll_question = $c->stash->{collection}->find($poll_question_id);
    $c->detach("/error_404") unless ref $poll_question;

    my $poll = $c->model("DB::Poll")->search( { id => $poll_question->poll_id } )->next;
    $c->detach("/error_404") unless ref $poll;

    $c->stash->{is_me}  = int($c->user->id == $poll->politician_id);
    $c->stash->{poll_question} = $poll_question;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;