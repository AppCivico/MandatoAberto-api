package MandatoAberto::Routes;
use strict;
use warnings;

sub register {
    my $r = shift;

    my $api = $r->route('/api');

    # Chatbot
    my $chatbot = $api->route('/chatbot')->under->to('chatbot#validade_security_token');

}

1;
