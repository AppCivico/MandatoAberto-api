package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::SchemaConnected;

sub startup {
    my $self = shift;

    # Helpers.
    $self->helper(detach => sub { die "MOJO_DETACH\n" });
    $self->helper(schema => sub { state $schema = MandatoAberto::SchemaConnected->get_schema(@_) });

    # Hooks.
    $self->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        return if eval { $next->(); 1 };
        die $@ unless $@ eq "MOJO_DETACH\n";
    });

    # Router
    my $r = $self->routes;

    # Normal route to controller
    my $api = $r->any('/api');
    my $register = $api->any('/register');
    $register->post('/politician')->to('register-politician#post');
}

1;
