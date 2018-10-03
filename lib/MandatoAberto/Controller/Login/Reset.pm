package MandatoAberto::Controller::Login::Reset;
use Mojo::Base 'Mojolicious::Controller';

sub post {
    my $c = shift;

	my $forgot_password = $c->schema->resultset('UserForgotPassword')->search(
		{
			token       => $c->stash->{token},
			valid_until => { '>=', \'NOW()' },
		}
	)->next;

	if ($forgot_password) {
		$forgot_password->execute(
			$c,
			for  => "reset",
			with => $c->req->params->to_hash,
		);
	}

    return $c->render(
        json   => { message => 'ok' },
        status => 200,
    );
}

1;

