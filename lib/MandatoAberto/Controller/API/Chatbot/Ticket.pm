package MandatoAberto::Controller::API::Chatbot::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('ticket') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $rs = $c->model('DB::Ticket');

    if ($c->req->params->{message} && ref $c->req->params->{message} ne 'ARRAY') {
        $c->req->params->{message} = [$c->req->params->{message}];
    }

    my $ticket = $rs->execute(
        $c,
        for  => 'create',
        with => $c->req->params
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller('API::Chatbot::Ticket'), $ticket->id),
        entity   => { id => $ticket->id }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $fb_id = $c->req->params->{fb_id} or die \['fb_id', 'missing'];

    my $rs = $c->model('DB::Ticket')->search_rs(
        { 'recipient.fb_id' => $fb_id },
        { join => 'recipient' }
    );

    return $self->status_ok(
        $c,
        entity   => $rs->build_list
    );
}

__PACKAGE__->meta->make_immutable;

1;
