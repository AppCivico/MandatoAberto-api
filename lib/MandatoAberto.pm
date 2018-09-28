package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::SchemaConnected;

sub startup {
    my $self = shift;

    # Helpers.
    $self->helper(schema => sub { state $schema = MandatoAberto::SchemaConnected->get_schema(@_) });

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('example#welcome');
}

1;
