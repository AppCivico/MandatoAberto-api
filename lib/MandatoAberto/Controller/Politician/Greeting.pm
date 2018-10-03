package MandatoAberto::Controller::Politician::Greeting;
use Mojo::Base 'Mojolicious::Controller';

#__PACKAGE__->config(
#    result  => "DB::PoliticianGreeting",
#    no_user => 1,
#
#);

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

sub list_GET {
    my ( $self, $c ) = @_;

    my $politician_id = $c->user->id;

    return $self->status_ok(
        $c,
        entity => {
            on_facebook => $c->stash->{politician}->politicians_greeting->next->on_facebook,
            on_website  => $c->stash->{politician}->politicians_greeting->next->on_website
        }
    );
}

1;

