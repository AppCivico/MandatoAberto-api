package MandatoAberto::Controller::API::Admin::Politician;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/admin/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            $c->stash->{collection}->get_politicians_with_pendencies
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;