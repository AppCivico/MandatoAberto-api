package MandatoAberto::Controller::Chatbot;
use Mojo::Base 'MandatoAberto::Controller';

use MandatoAberto::Utils;

sub validade_security_token {
    my $c = shift;

    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    if ( $security_token ne $c->req->params->to_hash->{security_token} ) {
	      $c->reply_forbidden();
	      $c->detach;
    }
    return $c;
}

sub get {
    my $c = shift;

	$c->validate_request_params(
		fb_page_id => {
			type     => 'Str',
			required => 1,
		},
	);

    my $page_id = $c->req->params->to_hash->{fb_page_id};

    return $c->render(
        status => 200,
        json   => {
            map {
                my $c = $_;

                politician_id    => $c->get_column('id'),
                politician_email => $c->get_column('email'),
                access_token     => $c->politician->get_column('fb_page_access_token')

            } $c->schema->resultset('User')->search(
                { 'politician.fb_page_id' => $page_id },
                { prefetch => 'politician' }
            )->next
        }
    );
}

1;
