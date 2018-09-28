package MandatoAberto::Controller::API::Admin::Movement::Discount;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::MovementDiscount",
);

sub root : Chained('/api/admin/movement/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('discount') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;