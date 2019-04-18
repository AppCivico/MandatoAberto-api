package MandatoAberto::Controller::User;
use Mojo::Base 'MandatoAberto::Controller';

sub post {
    my $c = shift;

    my $user = $c->schema->resultset('User')->execute(
        $c,
        for  => 'create',
        with => $c->req->params->to_hash,
    );

    $c->render(
        status => 201,
        json   => { id => $user->id }
    );
}

1;