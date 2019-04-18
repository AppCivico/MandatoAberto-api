package MandatoAberto;
use Mojo::Base 'Mojolicious';

use MandatoAberto::Config;
use MandatoAberto::Routes;
use MandatoAberto::Authentication;
use MandatoAberto::Authorization;
use MandatoAberto::Controller;
use MandatoAberto::SchemaConnected;
use MandatoAberto::Logger;

sub startup {
    my $self = shift;

	# Helpers.
	$self->helper(schema => sub { state $schema = MandatoAberto::SchemaConnected->get_schema(@_) });

	# force load of ENV before plugins
	$self->schema;

	# nao precisa manter conexao no processo manager
	$self->schema->storage->dbh->disconnect unless $ENV{HARNESS_ACTIVE};

	# Config.
	MandatoAberto::Config::setup($self);

    # Plugins.
    $self->plugin('Detach');
	$self->plugin('ParamLogger', filter => [qw(password)]);

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

    # Overwrite default helpers.
    $self->controller_class('MandatoAberto::Controller');
    $self->helper('reply.exception' => sub { MandatoAberto::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { MandatoAberto::Controller::reply_not_found(@_) });

    # Router.
    MandatoAberto::Routes::register($self->routes);
}

1;
