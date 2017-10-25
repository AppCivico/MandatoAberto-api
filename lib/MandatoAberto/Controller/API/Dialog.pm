package MandatoAberto::Controller::API::Dialog;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
# with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Dialog",

    # AutoResultPUT.
    object_key     => "dialog",
    result_put_for => "update",
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $dialog_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $dialog_id } );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    
}

__PACKAGE__->meta->make_immutable;

1;