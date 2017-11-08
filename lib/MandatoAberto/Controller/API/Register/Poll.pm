package MandatoAberto::Controller::API::Register::Poll;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

__PACKAGE__->config(
    result  => "DB::Poll",
    no_user => 1,
);

with "CatalystX::Eta::Controller::AutoBase";

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $poll = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => { politician_id => $c->user->id }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Poll")->action_for('result'), [ $poll->id ]),
        entity   => { id => $poll->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;