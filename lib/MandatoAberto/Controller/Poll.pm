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

1;
