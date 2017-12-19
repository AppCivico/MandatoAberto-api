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

    my $page_id = $c->req->params->{fb_page_id};
    die \["fb_page_id", "missing"] unless $page_id;

    return $self->status_ok(
        $c,
        entity => {
            map {
                my $p = $_;

                id        => $p->get_column('id'),
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
                                        id      => $o->get_column('id'),
                                        content => $o->get_column('content')
                                    }
                                } $q->question_options->all()
                            ]
                        }
                    } $p->poll_questions->all()
                ],
            } $c->model("DB::Poll")->search(
                {
                    'politician.fb_page_id' => $page_id,
                    status_id               => 1
                },
                { prefetch => [ 'poll_questions', { 'poll_questions' => "question_options" }, 'politician' ] }
            )
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;