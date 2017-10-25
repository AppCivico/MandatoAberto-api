package MandatoAberto::Controller::API::Register::Politian;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

__PACKAGE__->config(
    result  => "DB::Politian",
    no_user => 1,
);

with "CatalystX::Eta::Controller::AutoBase";

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politian') : CaptureArgs(0) { }

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $user = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

    $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Politian")->action_for('result'), [ $user->id ]),
        entity   => { id => $user->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;