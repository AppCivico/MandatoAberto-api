package MandatoAberto::Controller::Register::Politician;
use Mojo::Base 'Mojolicious::Controller';

use MandatoAberto::Utils qw(is_test);

sub post {
    my $c = shift;

    my $user = $c->schema->resultset('Politician')->execute(
        $c,
        for  => "create",
        with => $c->req->params->to_hash,
    );

    $c->render(
        status => 201,
        json   => { id => $user->id }
    );
}

1;
