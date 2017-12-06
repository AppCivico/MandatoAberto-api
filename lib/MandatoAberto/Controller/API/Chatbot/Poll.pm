package MandatoAberto::Controller::API::Chatbot::Poll;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianChatbot",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_chatbot = $c->stash->{collection}->find($c->user->id);

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $p = $_;

                name      => $p->get_column('name'),
                questions => [
                    map {
                        my $q = $_;

                        +{
                            content => $q->get_column('content'),

                            options => [
                                map {
                                    my $o = $_;

                                    +{
                                        content => $o->get_column('content')
                                    }
                                } $q->question_options->all()
                            ]
                        }
                    } $p->poll_questions->all()
                ],
            } $c->model("DB::Poll")->search(
                {
                    politician_id => $politician_chatbot->politician_id,
                    active        => 1
                },
                { prefetch => [ 'poll_questions', { 'poll_questions' => "question_options" } ] }
            )
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;