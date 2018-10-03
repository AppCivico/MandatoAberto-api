package MandatoAberto::Controller::Politician::Greeting;
use Mojo::Base 'Mojolicious::Controller';

sub post {
    my $c = shift;

    my $politician_greeting = $c->schema->resultset('PoliticianGreeting')->execute(
        $c,
        for  => 'create',
        with => {
            %{ $c->req->params->to_hash },
            politician_id => $c->current_user->id,
          }
    );

    return $c->render(
        json   => { id => $politician_greeting->id },
        status => 200,
    );
}

sub get {
    my $c = shift;

    return $c->render(
        json   => {
            on_facebook => $c->stash('politician')->politicians_greeting->next->on_facebook,
            on_website  => $c->stash('politician')->politicians_greeting->next->on_website
        }
    );
}

1;

