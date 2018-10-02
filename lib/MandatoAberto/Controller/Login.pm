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
        my $ipAddr = $c->req->header("CF-Connecting-IP") || $c->req->header("X-Forwarded-For") || $c->req->address;

        my $session = $c->user->obj->new_session(
            %{ $c->req->params->to_hash },
            ip => $ipAddr,
        );

        return $c->render(
            json   => $session,
            status => 200,
        );
    }

    return $c->render(
        json   => { error => 'Bad email or password' },
        status => 200,
    );

    return $c->status_bad_request($c, message => 'Bad email or password.');
}

1;
