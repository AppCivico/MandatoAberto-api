package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::Authentication;
use MandatoAberto::Controller;
use MandatoAberto::SchemaConnected;

sub startup {
    my $self = shift;

    # Plugins.
    $self->plugin('Detach');
    #$self->plugin(bcrypt => { cost => 6 });
    $self->plugin('SimpleAuthentication');

    # Helpers.
    $self->helper(schema => sub { state $schema = MandatoAberto::SchemaConnected->get_schema(@_) });

    # Overwrite default helpers.
    $self->controller_class('MandatoAberto::Controller');
    $self->helper('reply.exception' => sub { MandatoAberto::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { MandatoAberto::Controller::reply_not_found(@_) });

    # Router
    my $r = $self->routes;

    my $api = $r->route('/api');

    # Register.
    my $register = $api->route('/register');
    $register->post('/politician')->to('register-politician#post');

    # Login.
    $api->post('/login')->to('login#post');

    # Admin.
    #my $admin = $api->any('/admin')->over(authenticated => 1);
    my $admin = $api->route('/admin');

    # Admin::Politician
    my $admin_politician = $admin->route('/politician');
    $admin_politician->post('/approve')->to('admin-politician-approve#post')->over(authenticated => 1);
}

1;
