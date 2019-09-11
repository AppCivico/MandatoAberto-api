package MandatoAberto::Controller::API::Chatbot::Questionnaire::Pending;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/questionnaire/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('pending') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{questionnaire_stash}->next_pending_question()
    );
}

__PACKAGE__->meta->make_immutable;

1;
