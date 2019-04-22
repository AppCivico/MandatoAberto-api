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
    $login->post()->to(controller => 'Login', action => 'post');

    # Organization
    my $organization_list   = $r->route('/organization');
    my $organization_result = $organization_list->under('/:organization_id')->to(controller => 'Organization', action => 'load');
	$organization_result->get()->to(controller => 'Organization', action => 'get');
	$organization_result->put()->to(controller => 'Organization', action => 'put');
}

1;
