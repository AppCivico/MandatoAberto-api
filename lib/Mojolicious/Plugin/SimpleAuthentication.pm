package Mojolicious::Plugin::SimpleAuthentication;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    ref $args->{load_user}     eq 'CODE' or die __PACKAGE__ . ": 'load_user' should be a subroutine ref\n";
    ref $args->{validate_user} eq 'CODE' or die __PACKAGE__ . ": 'validate_user' should be a subroutine ref\n";

    my $stash_key         = $args->{stash_key}       || '__authentication__';
    my $current_user_fn   = $args->{current_user_fn} || 'current_user';
    my $load_user_cb      = $args->{load_user};
    my $validate_user_cb  = $args->{validate_user};

    my $fail_render = ref $args->{fail_render} eq 'CODE'
       ? $args->{fail_render} : sub { $args->{fail_render} };

    my $user_loader_sub = sub {
        my $c = shift;

        my $user = $load_user_cb->($c);
        if (ref $user) {
            $c->stash($stash_key => { user => $user });
        }
        else {
            $c->stash($stash_key => { no_user => 1 });
        }
    };

    my $user_stash_extractor_sub = sub {
        my ($c, $user) = @_;

        if (defined $user) {
            $c->stash($stash_key => { user => $user });
            return;
        }

        my $stash = $c->stash($stash_key);
        $user_loader_sub->($c) unless $stash->{no_user} or defined $stash->{user};

        $stash = $c->stash($stash_key);
        return $stash->{user};
    };

    $app->hook(before_dispatch => $user_loader_sub);

    $app->routes->add_condition(authenticated => sub {
        my ($r, $c, $captures, $required) = @_;
        my $res = (!$required or $c->is_user_authenticated);

        unless ($res) {
          my $fail = $fail_render->(@_);
          $c->render(%{$fail}) if $fail;
        }
        return $res;
    });

    my $current_user = sub {
        return $user_stash_extractor_sub->(@_);
    };

    $app->helper(reload_user => sub {
        my $c = shift;

        delete $c->stash->{$stash_key};
        return $current_user->($c);
    });

    $app->helper(is_user_authenticated => sub {
        my $c = shift;
        return defined $current_user->($c);
    });

    $app->helper($current_user_fn => $current_user);

    # TODO Logout.

    $app->helper(authenticate => sub {
        my $c = shift;

        my $user = $validate_user_cb->($c, @_);

        if (ref $user) {
            delete $c->stash->{$stash_key};

            $c->stash($stash_key => { user => $user });

            return 1 if defined $current_user->($c);
        }
        return;
    });
}

1;
