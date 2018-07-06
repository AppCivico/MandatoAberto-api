package MandatoAberto::Controller::API::Admin::Movement;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoListPOST";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Movement",

    # AutoResultPUT.
    object_key     => "movement",
    result_put_for => "update",

    # AutoListGET
    list_key => "movements",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/admin/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('movement') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $movement_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $movement_id } );

    my $movement = $c->stash->{collection}->find($movement_id);
    $c->detach("/error_404") unless ref $movement;

    $c->stash->{movement} = $movement;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;