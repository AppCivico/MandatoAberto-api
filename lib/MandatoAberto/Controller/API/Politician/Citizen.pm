package MandatoAberto::Controller::API::Politician::Citizen;
use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    result  => "DB::Citizen",
    no_user => 1,

    list_key => "citizens",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('citizen') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ($self, $c, $citizen_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $citizen_id } );

    my $citizen = $c->stash->{collection}->find($citizen_id);
    $c->detach("/error_404") unless ref $citizen;

    $c->stash->{citizen} = $citizen;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    # TODO validar como será a autenticação do chatbot

    my $citizen = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{ $c->req->params },
            politician_id => $c->user->id
        }
    );

    return $self->status_ok(
        $c,
        entity => {
            id => $citizen->id
        }
    );
}

sub list_GET { }

__PACKAGE__->meta->make_immutable;

1;