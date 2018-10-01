package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::Controller;
use MandatoAberto::SchemaConnected;

sub startup {
    my $self = shift;

    $self->plugin('Detach');

    # Helpers.
    $self->helper(schema => sub { state $schema = MandatoAberto::SchemaConnected->get_schema(@_) });

    # Overwrite default helpers.
    $self->controller_class('MandatoAberto::Controller');
    $self->helper('reply.exception' => sub { MandatoAberto::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { MandatoAberto::Controller::reply_not_found(@_) });

    # Router
    my $r = $self->routes;

    # Normal route to controller
    my $api = $r->any('/api');
    my $register = $api->any('/register');
    $register->post('/politician')->to('register-politician#post');
}

1;
