package MandatoAberto::Controller::API::Chatbot::Questionnaire::Reset;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/questionnaire/base') : PathPart('') :
  CaptureArgs(0) { }

sub base : Chained('root') : PathPart('reset') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ( $self, $c ) = @_;

    $c->stash->{questionnaire_stash}->reset();

    return $self->status_ok(
        $c,
        entity => { message => 'ok' } );
}

__PACKAGE__->meta->make_immutable;

1;
