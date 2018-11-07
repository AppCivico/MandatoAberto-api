package MandatoAberto::Controller::Poll;
use Mojo::Base 'MandatoAberto::Controller';

use DateTime;

sub item_stasher {
    my $c = shift;

    my $poll_id = $c->param('poll_id');

    my $poll = $c->schema->resultset('Poll')->search(
        {
            'me.id'            => $poll_id,
            'me.politician_id' => $c->current_user->id,
        }
    )->next;

    if (!ref $poll) {
        $c->reply_not_found;
        $c->detach();
    }

    $c->stash(poll => $poll);

    return $c;
}

sub item_put {
    my $c = shift;

    my $poll = $c->stash('poll')->execute(
        $c,
        for => 'update',
        with => $c->req->params->to_hash,
    );

    return $c->render(
        status => 202,
        json   => { id => $poll->id }
    )
}

sub get {
    my $c = shift;

    my $politician_id = $c->current_user->id;

    return $c->render(
        status => 200,
        json   => {
            polls => [
                map {
                    my $p = $_;

                    +{
                        id          => $p->get_column('id'),
                        name        => $p->get_column('name'),
                        status_id   => $p->get_column('status_id'),

                        ( $p->status_id == 1 ? ( active_time => $p->created_at->subtract_datetime( DateTime->now() ) ) : ( ) ),

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
                } $c->schema->resultset('Poll')->search(
                    { 'me.politician_id' => $politician_id },
                    { prefetch => [ 'poll_questions' , { 'poll_questions' => { "poll_question_options" => 'poll_results' } } ] }
                )->all()
            ],
        }
    );
}

1;
