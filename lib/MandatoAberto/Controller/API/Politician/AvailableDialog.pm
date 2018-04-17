package MandatoAberto::Controller::API::Politician::AvailableDialog;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Answer",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('available-dialogs') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            $c->stash->{politician}->answers->get_answered_dialogs
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
