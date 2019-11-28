package MandatoAberto::Controller::API::Politician::Ticket::Types;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/politician/ticket/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('types') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->user->organization->organization_ticket_types;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $ticket_type_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $ticket_type_id } );

    my $ticket_type = $c->stash->{collection}->find($ticket_type_id);
    $c->detach("/error_404") unless ref $ticket_type;

    $c->stash->{is_me} = $ticket_type->organization->user_organizations->search( { user_id => $c->user->id } )->count;
    $c->stash->{ticket_type} = $ticket_type;

    $c->detach("/api/forbidden") unless $c->stash->{is_me} == 1;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{collection}->build_list(page => $c->req->params->{page}, results => $c->req->params->{results}, build_for_front_end => 1)
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{ticket_type}->build_list
    );
}

sub result_PUT {
    my ($self, $c) = @_;

    # Tratando caso de limpeza de params 'send_email_to' e de horario.
    if ( $c->req->params->{send_email_to} eq '__DELETE__' ) {
        $c->req->params->{delete_send_email_to} = 1;
        delete $c->req->params->{send_email_to};
    }

    my $ticket_type = $c->stash->{ticket_type}->execute(
        $c,
        for  => 'update',
        with => $c->req->params
    );

    return $self->status_ok(
        $c,
        entity => { id => $ticket_type->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;