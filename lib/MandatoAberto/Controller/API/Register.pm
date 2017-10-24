package MandatoAberto::Controller::API::Register;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    result  => "DB::Politian",
    no_user => 1,
);

sub root :Chained('/api/root') :PathPart('') :CaptureArgs(0) { }

sub base :Chained('root') :PathPart('politian') :CaptureArgs(0) { }

sub create : Chained('base') : PathPart('register') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $user = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

    $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::User")->action_for('user'), [ $user->id ]),
        entity   => { id => $user->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;