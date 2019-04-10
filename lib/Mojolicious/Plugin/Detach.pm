package Mojolicious::Plugin::Detach;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    my $random_string = $self->_get_random_string();

    $app->helper(detach => sub { die "$random_string\n" });

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        return if eval { $next->(); 1 };
        die $@ unless $@ eq "$random_string\n";
    });
}

sub _get_random_string {
    my @chars = ("A".."Z", "a".."z");
    my $string;
    $string .= $chars[rand @chars] for 1..16;

    return $string;
}

1;
