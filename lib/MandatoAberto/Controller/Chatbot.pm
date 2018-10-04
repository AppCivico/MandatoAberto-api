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

1;
