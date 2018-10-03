package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::Authentication;
use MandatoAberto::Authorization;
use MandatoAberto::Controller;
use MandatoAberto::SchemaConnected;

sub startup {
    my $self = shift;

    # Plugins.
    $self->plugin('Detach');

    $self->plugin('SimpleAuthentication', {
        load_user     => sub { MandatoAberto::Authentication::load_user(@_)     },
        validate_user => sub { MandatoAberto::Authentication::validate_user(@_) },
    });

    $self->plugin(
        authorization => {
            has_priv    => sub { return MandatoAberto::Authorization->has_priv(@_)   },
            is_role     => sub { return MandatoAberto::Authorization->is_role(@_)    },
            user_privs  => sub { return MandatoAberto::Authorization->user_privs(@_) },
            user_role   => sub { return MandatoAberto::Authorization->user_role(@_)  },
            fail_render => MandatoAberto::Authorization->fail_render(),
        }
    );

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
    my $admin = $api->route('/admin')->over(authenticated => 1)->over(has_priv => 'admin');

    # Admin::Politician
    my $admin_politician = $admin->route('/politician');
    $admin_politician->post('/approve')->to('admin-politician-approve#post');

    # Politician.
    my $politician = $api->route('/politician')->over(has_priv => ['politician', 'admin']);
    $politician->get('/:id')->to('politician#get');
    $politician->post('/:id/contact')->to('politician-contact#post');
    $politician->post('/:id/greeting')->to('politician-greeting#post');
}

1;
