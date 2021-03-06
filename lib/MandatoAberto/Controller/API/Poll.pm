package MandatoAberto::Controller::API::Poll;
use Moose;
use namespace::autoclean;

use DateTime;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Poll",

    # AutoResultPUT.
    object_key     => "poll",
    result_put_for => "update",

    # AutoListGET
    list_key => "poll",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_id } );

    my $poll = $c->stash->{collection}->find($poll_id);
    $c->detach("/error_404") unless ref $poll;

    my $politician = $c->model('DB::Politician')->find($c->user->id);
    $c->detach("/error_404") unless ref $politician;

    $c->stash->{is_me} = int($politician->user->organization_chatbot_id == $poll->organization_chatbot_id);
    $c->stash->{poll}  = $poll;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;
    my $politician    = $c->model('DB::Politician')->find($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    my $now = DateTime->now;

	my $page    = $c->req->params->{page}    || 1;
	my $results = $c->req->params->{results} || 20;
	$results    = $results <= 20 ? $results : 20;

	my $total = $c->stash->{collection}->count;

    return $self->status_ok(
        $c,
        entity => {
            total => $total,
            polls => [
                map {
                    my $p = $_;

                    +{
                        id          => $p->get_column('id'),
                        name        => $p->get_column('name'),
                        created_at  => $p->created_at,

                        questions => [
                            map {
                                my $pq = $_;
                                +{
                                    id      => $pq->get_column('id'),
                                    content => $pq->get_column('content'),

                                    options => [
                                        map {
                                            my $qo = $_;

                                            +{
                                                id      => $qo->get_column('id'),
                                                content => $qo->get_column('content'),
                                                count   => $qo->poll_results->search()->count,
                                            }
                                        } $pq->poll_question_options->all()
                                    ]
                                }

                            } $p->poll_questions->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { 'me.organization_chatbot_id' => $organization_chatbot_id },
                    {
                        prefetch => [ 'poll_questions' , { 'poll_questions' => { "poll_question_options" => 'poll_results' } } ],
                        page     => $page,
                        rows     => $results
                    }
                )->all()
            ],
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            id        => $c->stash->{poll}->id,
            name      => $c->stash->{poll}->name,
            questions => [
                map {
                    my $pq = $_;

                    +{
                        id      => $pq->get_column('id'),
                        content => $pq->get_column('content'),

                        options => [
                            map {
                                my $qo = $_;

                                +{
                                    id      => $qo->get_column('id'),
                                    content => $qo->get_column('content'),
                                    count   => $qo->poll_results->search( { origin => 'propagate' } )->count,
                                  }
                            } $pq->poll_question_options->all()
                        ]
                    }

                } $c->stash->{poll}->poll_questions->all()
            ]

        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
