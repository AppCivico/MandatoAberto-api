package MandatoAberto::Controller::API::Dialog::Question::Answer;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    result  => "DB::Answer",
    no_user => 1,

    object_key => "answer",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{question_id}   = $c->stash->{question}->id;
        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/dialog/question/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('answer') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $answer_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $answer_id } );

    my $answer = $c->stash->{collection}->find($answer_id);
    $c->detach("/error_404") unless ref $answer;

    $c->stash->{answer} = $answer;

    $c->stash->{is_me} = int($c->user->id == $answer->politician_id);
    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;