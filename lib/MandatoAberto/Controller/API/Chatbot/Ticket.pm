package MandatoAberto::Controller::API::Chatbot::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('ticket') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $ticket_id) = @_;

    $c->stash->{collection} = $c->model('DB::Ticket')->search_rs( { id => $ticket_id } );

    my $ticket = $c->stash->{collection}->find($ticket_id);
    $c->detach("/error_404") unless ref $ticket;

    $c->stash->{ticket} = $ticket;
}

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

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT {
    my ($self, $c) = @_;

    if ( $c->req->params->{status} ) {
        die \['status', 'invalid'] unless $c->req->params->{status} eq 'canceled';
    }

    my $ticket = $c->stash->{ticket}->execute(
        $c,
        for  => 'update',
        with => {
            message            => $c->req->params->{message},
            status             => $c->req->params->{status},
            updated_by_chatbot => 1,
        }
    );

    return $self->status_ok(
        $c,
        entity => { id => $ticket->id }
    )
}

__PACKAGE__->meta->make_immutable;

1;
