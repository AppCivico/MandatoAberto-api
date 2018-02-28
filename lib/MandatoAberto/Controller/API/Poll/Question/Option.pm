package MandatoAberto::Controller::API::Poll::Question::Option;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::QuestionOption",
    no_user => 1,

    # AutoResultPUT.
    object_key     => "question_options",
    result_put_for => "update",
    build_row      => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{question_id} = $c->stash->{poll_questions}->id;

        return $params;
    },
);

sub root : Chained('/api/poll/question/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('option') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $option_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $option_id } );

    my $option = $c->stash->{collection}->find($option_id);
    $c->detach("/error_404") unless ref $option;

    $c->stash->{question_options} = $option;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;