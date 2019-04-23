package MandatoAberto::Controller::Chatbot;
use Mojo::Base 'MandatoAberto::Controller';

sub load {
	my $c = shift;

	$c->validate_request_params(
		page_id => {
			type     => 'Str',
			required => 1,
		},
        security_token => {
			type     => 'Str',
			required => 1,
		},
	);

    # Validando security_token
    my $security_token = $ENV{'CHATBOT_SECURITY_TOKEN'};
	if ( $security_token ne $c->req->params->to_hash->{security_token} ) {
		$c->reply_forbidden();
		$c->detach;
	}

    # Carregando chatbot
	my $page_id = $c->req->params->to_hash->{page_id};

	my $chatbot = $c->schema->resultset('OrganizationChatbot')->search(
        { 'organization_chatbot_facebook_config.page_id' => $page_id },
        { prefetch => 'organization_chatbot_facebook_config' }
    )->next;

	if (!ref $chatbot) {
		$c->reply_not_found;
		$c->detach();
	}

	$c->stash(chatbot => $chatbot);

	return $c;
}

sub get {
    my $c = shift;

    my $chatbot = $c->stash->{chatbot};

    $c->render(
        status => 200,
        json   => {
            map { $_ => $chatbot->$_ } qw( id name )
        }
    )
}

1;