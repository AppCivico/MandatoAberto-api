package MandatoAberto::Controller::API::Organization::Chatbot::Label;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/organization/chatbot/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('label') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{chatbot}->labels;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $label_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $label_id } );

    my $label = $c->stash->{collection}->find($label_id);
    $c->detach("/error_404") unless ref $label;

    $c->stash->{is_me} = $label->organization_chatbot->organization->user_organizations->search( { user_id => $c->user->id } )->count;
    $c->stash->{label} = $label;

    $c->detach("/api/forbidden") unless $c->stash->{is_me} == 1;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{collection}->labels_GET
    );
}

sub list_POST {
    my ($self, $c) = @_;

    my $label = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Organization::Chatbot::Label"), [ $label->id ]),
        entity   => { id => $label->id }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    return $c->stash->{label}->label_GET;
}

__PACKAGE__->meta->make_immutable;

1;