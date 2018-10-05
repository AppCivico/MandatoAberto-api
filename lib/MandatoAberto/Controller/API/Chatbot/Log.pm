package MandatoAberto::Controller::API::Chatbot::Log;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('log') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $rs = $c->model('DB::Log');

    my $log = $rs->execute(
        $c,
        for  => 'create',
        with => $c->req->params
    );

    return $self->status_ok(
        $c,
        entity   => { success => 1 }
    );
}

__PACKAGE__->meta->make_immutable;

1;
