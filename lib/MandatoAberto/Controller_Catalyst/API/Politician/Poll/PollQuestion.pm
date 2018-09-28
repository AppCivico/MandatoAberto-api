package MandatoAberto::Controller::API::Politician::Poll::PollQuestion;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollQuestion",
);

sub root : Chained('/api/politician/poll/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('questions') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_question_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_question_id } );

    my $poll_question = $c->stash->{collection}->find($poll_question_id);
    $c->detach("/error_404") unless ref $poll_question;

    $c->stash->{is_me} = int($c->user->id == $c->stash->{poll}->politician_id);
    $c->stash->{poll_question}  = $poll_question;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    my $question = $c->stash->{poll_question};

    return $self->status_ok(
        $c,
        entity => {
            id      => $question->id,
            content => $question->content,

            options => [
                map {
                    my $qo = $_;

                    {
                        id      => $qo->get_column('id'),
                        content => $qo->get_column('content')
                    }
                } $question->poll_question_options->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;