package MandatoAberto::Controller::Organization::Chatbot;
use Mojo::Base 'MandatoAberto::Controller';

sub load {
	my $c = shift;

	my $chatbot_id = $c->param('chatbot_id');
	my $chatbot    = $c->schema->resultset('OrganizationChatbot')->search( { 'me.id' => $chatbot_id } )->next;

    if (!ref $chatbot) {
		$c->reply_not_found;
		$c->detach();
	}

	$c->stash(chatbot => $chatbot);

    # Verificando se o usuário faz parte da organização
	if ( $c->stash('organization')->id != $chatbot->organization_id ) {
		$c->reply_forbidden();
		$c->detach;
	}

	return $c;
}

sub get {
    my $c = shift;

    my $organization = $c->stash('organization');

    return $c->render(
        status => 200,
        json   => {
            chatbots => [
                map {
                   +{
                        id        => $_->id,
                        picture   => $_->picture,
                        name      => $_->name,
                        fb_config => $_->fb_config_for_GET
                    }
                } $organization->chatbots->all()
            ]
        }
    );
}

sub get_result {
    my $c = shift;

    my $chatbot = $c->stash('chatbot');

    return $c->render(
        status => 200,
        json   => {
            id        => $chatbot->id,
            picture   => $chatbot->picture,
            name      => $chatbot->name,
            fb_config => $chatbot->fb_config_for_GET
        }
    );
}

sub put {
    my $c = shift;

	my $chatbot = $c->stash->{chatbot}->execute(
		$c,
		for  => 'update',
		with => $c->req->params->to_hash
	);

	return $c->render(
		status => 202,
		json   => {
			id => $chatbot->id
		}
	);
}

1;
