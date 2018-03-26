package MandatoAberto::Controller::API::Register::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

__PACKAGE__->config(
    result  => "DB::Politician",
    no_user => 1,
);

with "CatalystX::Eta::Controller::AutoBase";

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) { }

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $user = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

    $c->slack_notify("O usuário ${\($user->name)} se cadastrou na plataforma.") unless is_test();

    $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Politician")->action_for('result'), [ $user->id ]),
        entity   => { id => $user->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;