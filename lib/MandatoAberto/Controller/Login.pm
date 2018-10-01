package MandatoAberto::Controller::Login;
use Mojo::Base 'MandatoAberto::Controller';

use MandatoAberto::Types qw(EmailAddress);

sub post {
    my $c = shift;

    my $email = $c->req->param('email') || '';
    $c->req->params->param(email => lc $email);
    if (length $email < 3) {
        die \['email', 'missing'];
    }

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

    if ($user) {
        $user->approved == 1 ? () : die \['approved', 'user not approved']
    }

    my $authenticate = $c->authenticate({
        ( map { $_ => $c->req->params->param($_) } qw(email password) ),
        approved => 1
    });

    if ($authenticate) {
        my $ipAddr = $c->req->header("CF-Connecting-IP") || $c->req->header("X-Forwarded-For") || $c->req->address;

        my $session = $c->user->obj->new_session(
            %{ $c->req->params->to_hash },
            ip => $ipAddr,
        );

        return $c->status_ok($c, entity => $session);
    }

    return $c->status_bad_request($c, message => 'Bad email or password.');
}

1;
