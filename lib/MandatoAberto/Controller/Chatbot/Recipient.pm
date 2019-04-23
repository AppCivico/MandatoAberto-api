package MandatoAberto::Controller::Chatbot::Recipient;
use Mojo::Base 'MandatoAberto::Controller';

sub post {
	my $c = shift;

	my $recipient = $c->stash->{chatbot}->recipients->execute(
		$c,
		for  => 'create',
		with => $c->req->params->to_hash,
	);

	$c->render(
		status => 201,
		json   => { id => $recipient->id }
	);
}

1;
