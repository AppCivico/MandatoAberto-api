package MandatoAberto::Routes;
use strict;
use warnings;

sub register {
    my $r = shift;

    # User
    my $user = $r->route('/user');
    $user->post()->to(controller => 'User', action => 'post');

    # Login
    my $login = $r->route('/login');

}

1;
