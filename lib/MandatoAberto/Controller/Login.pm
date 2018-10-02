package MandatoAberto::Controller::Login;
use Mojo::Base 'MandatoAberto::Controller';

use MandatoAberto::Types qw(EmailAddress);

sub post {
    my $c = shift;

    my $email = $c->req->param('email') || q{};
    $c->req->params->param(email => lc $email);
    $email = $c->req->param('email');
    die \['email', 'missing'] unless length $email > 3;

    $c->validate_request_params(
        email => {
            type     => EmailAddress,
            required => 1,
        },
        password => {
            type     => "Str",
            required => 1,
        },
    );

    my $user = $c->schema->resultset('User')->search( { email => $c->req->param('email') } )->next;
    die \['email', 'email does not exists'] unless $user;

    if (ref $user) {
        $user->approved == 1 ? () : die \['approved', 'user not approved']
    }

    my $password = $c->req->param('password');

    if ($c->authenticate($email, $password)) {
        my $ip_address = $c->req->headers->header("CF-Connecting-IP") || $c->req->headers->header("X-Forwarded-For") || $c->tx->remote_address;

        my $session = $c->current_user->new_session(
            %{ $c->req->params->to_hash },
            ip => $ip_address,
        );

        return $c->render(
            json   => $session,
            status => 200,
        );
    }

    return $c->render(
        json   => { error => 'Bad email or password' },
        status => 400,
    );
}

1;
