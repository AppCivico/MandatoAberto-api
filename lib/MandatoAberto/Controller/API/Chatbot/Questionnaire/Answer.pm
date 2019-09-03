package MandatoAberto::Controller::API::Chatbot::Questionnaire::Answer;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/questionnaire/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('answer') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $answer = $c->model('DB::QuestionnaireAnswer')->execute(
        $c,
        for  => 'create',
        with => $c->req->params
    );

    return $self->status_ok(
        $c,
        entity => $c->stash->{questionnaire_stash}->next_pending_question()
    );
}

__PACKAGE__->meta->make_immutable;

1;
