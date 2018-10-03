package MandatoAberto::Controller::Login::ForgotPassword;
use Mojo::Base 'Mojolicious::Controller';

sub post {
    my $c = shift;

    $c->schema->resultset('UserForgotPassword')->execute(
        $c,
        for  => 'create',
        with => { %{ $c->req->params->to_hash } }
    );

    return $c->render(
        json   => { message => 'ok' },
        status => 200,
    );
}

1;

