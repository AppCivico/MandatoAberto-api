package MandatoAberto::Controller::API::Register;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root :Chained('/api/root') :PathPart('') :CaptureArgs(0) { }

sub base :Chained('root') :PathPart('register') :CaptureArgs(0) { }

sub register : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub register_POST {
    my ($self, $c) = @_;

    my $user = $c->model('DB::User')->execute(
        $c,
        for  => 'create_user',
        with => $c->req->params,
    );
    
    $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::User")->action_for('result'), [ $user->id ]),
        entity   => { id => $user->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;
