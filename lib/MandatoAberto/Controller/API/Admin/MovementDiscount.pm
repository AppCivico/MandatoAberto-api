package MandatoAberto::Controller::API::Admin::Dialog;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::MovementDiscount",

    # AutoResultPUT.
    object_key                => "movement_discount",
    result_put_for            => "update",
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        $params->{admin_id} = $c->user->id;

        return $params;
    },

    # AutoResultGET
    build_row => sub { return { $_[0]->get_columns() } },

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{admin_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/admin/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $dialog_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $dialog_id } );

    my $dialog = $c->stash->{collection}->find($dialog_id);
    $c->detach("/error_404") unless ref $dialog;

    $c->stash->{dialog} = $dialog;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            $c->stash->{collection}->get_dialogs_with_data
        }
    )
}

sub list_POST { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;