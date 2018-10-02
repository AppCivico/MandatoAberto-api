package MandatoAberto::Authentication;
use strict;
use warnings;

sub load_user {
    my $c = shift;

    my $api_key = $c->req->param('api_key') || $c->req->headers->header('X-API-Key');

    if (defined $api_key) {
        my $user_session = $c->app->schema->resultset('UserSession')->search(
            { 'me.api_key' => $api_key },
            { prefetch => [qw( user )] },
        )->next;

        if (ref $user_session) {
            return $user_session->user;
        }
    }
    return;
}

sub validate_user {
    my ($c, $email, $password) = @_;

    my $user = $c->schema->resultset('User')->search( { 'me.email' => $email } )->next;
    if (ref $user) {
        if ($user->check_password($password)) {
            return $user;
        }
    }
    return;
}

1;
