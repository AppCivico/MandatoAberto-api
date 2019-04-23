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

    # Organization::Chatbot
    my $chatbot_list   = $organization_result->route('/chatbot');
    my $chatbot_result = $chatbot_list->under('/:chatbot_id')->to(controller => 'Organization::Chatbot', action => 'load');
	$chatbot_list->get()->to(controller => 'Organization::Chatbot', action => 'get');
	$chatbot_result->get()->to(controller => 'Organization::Chatbot', action => 'get_result');
	$chatbot_result->put()->to(controller => 'Organization::Chatbot', action => 'put');
}

1;
