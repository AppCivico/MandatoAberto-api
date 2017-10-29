package MandatoAberto::Controller::API::Register::Dialog;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

__PACKAGE__->config(
    result  => "DB::Dialog",
    no_user => 1,
);

with "CatalystX::Eta::Controller::AutoBase";

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/admin/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $dialog = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

    $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Dialog")->action_for('result'), [ $dialog->id ]),
        entity   => {
            id   => $dialog->id,
            name => $dialog->name
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;