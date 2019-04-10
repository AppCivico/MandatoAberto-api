package MandatoAberto::Controller::API::Admin::Dialog::Question;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    result  => "DB::Question",
    no_user => 1,

    object_key => "question",
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        $params->{admin_id} = $c->user->id;

        return $params;
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{admin_id}  = $c->user->id;
        $params->{dialog_id} = $c->stash->{dialog}->id;

        return $params;
    },
);

sub root : Chained('/api/admin/dialog/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('question') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $question_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $question_id } );

    my $question = $c->stash->{collection}->find($question_id);
    $c->detach("/error_404") unless ref $question;

    $c->stash->{question} = $question;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;