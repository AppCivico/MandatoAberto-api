package MandatoAberto::Controller::API::Register::PollQuestion;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    result  => "DB::PollQuestion",
    no_user => 1,
);

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll-question') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $poll_question = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => { %{ $c->req->params} },
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::PollQuestion")->action_for('result'), [ $poll_question->id ]),
        entity   => { id => $poll_question->id }
    );
}
__PACKAGE__->meta->make_immutable;

1;