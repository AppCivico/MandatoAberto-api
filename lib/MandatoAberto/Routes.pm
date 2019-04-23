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
    my $organization_chatbot_list   = $organization_result->route('/chatbot');
    my $organization_chatbot_result = $organization_chatbot_list->under('/:chatbot_id')->to(controller => 'Organization::Chatbot', action => 'load');
	$organization_chatbot_list->get()->to(controller => 'Organization::Chatbot', action => 'get');
	$organization_chatbot_result->get()->to(controller => 'Organization::Chatbot', action => 'get_result');
	$organization_chatbot_result->put()->to(controller => 'Organization::Chatbot', action => 'put');

    # Chatbot
    my $chatbot = $r->under('/chatbot')->to(controller => 'Chatbot', action => 'load');
    $chatbot->get()->to(controller => 'Chatbot', action => 'load');

    # Chatbot::Recipient
    my $recipient_list = $chatbot->route('/recipient');
    $recipient_list->post()->to(controller => 'Chatbot::Recipient', action => 'post');

}

1;
