package MandatoAberto::Controller::API::Politician::Ticket;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('ticket') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->user->organization_chatbot->tickets;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $ticket_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $ticket_id } );

    my $ticket = $c->stash->{collection}->find($ticket_id);
    $c->detach("/error_404") unless ref $ticket;

    $c->stash->{is_me} = $ticket->organization_chatbot->organization->user_organizations->search( { user_id => $c->user->id } )->count;
    $c->stash->{ticket} = $ticket;

    $c->detach("/api/forbidden") unless $c->stash->{is_me} == 1;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{collection}->build_list($c->req->params->{page}, $c->req->params->{results})
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{ticket}->build_list
    );
}

sub result_PUT {
    my ($self, $c) = @_;

    $c->req->params->{user_id} = $c->user->id;
    use DDP; p $c->req->params;
    my $ticket = $c->stash->{ticket}->execute(
        $c,
        for  => 'update',
        with => $c->req->params
    );

    return $self->status_ok(
        $c,
        entity => { id => $ticket->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;