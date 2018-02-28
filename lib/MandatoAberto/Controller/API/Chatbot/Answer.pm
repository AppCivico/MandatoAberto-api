package MandatoAberto::Controller::API::Chatbot::Answer;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Answer",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('answer') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \["politician_id", "missing"] unless $politician_id;

    my $question_name = $c->req->params->{question_name};
    die \["question_name", "missing"] unless $question_name;

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $a = $_;

                content => $a->get_column('content');
            } $c->stash->{collection}->search(
                {
                    politician_id   => $politician_id,
                    'question.name' => $question_name
                },
                { prefetch => 'question' }
            )->all
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;