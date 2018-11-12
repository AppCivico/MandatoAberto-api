package MandatoAberto::Routes;
use strict;
use warnings;

sub register {
    my $r = shift;

    my $api = $r->route('/api');

    # Register.
    my $register = $api->route('/register');
    $register->post('/politician')->to('register-politician#post');

    # Register::Poll.
    $register->post('/poll')->to('register-poll#post')->over(has_priv => 'politician');

    # Login.
    my $login = $api->route('/login');
    $login->post('/')->to('login#post');

    # Login::ForgotPassword
    my $forgot_password = $login->route('/forgot_password');
    $forgot_password->post('/')->to('login-forgot_password#post');

    # Login::Reset
    my $reset = $forgot_password->route('/reset');
    $reset->post('/:token')->to('login-reset#post');

    # Admin.
    my $admin = $api->route('/admin')->over(authenticated => 1)->over(has_priv => 'admin');

    # Admin::Politician
    my $admin_politician = $admin->route('/politician');
    $admin_politician->post('/approve')->to('admin-politician-approve#post');

    # Admin::Dialog.
    my $admin_dialog = $admin->route('/dialog');
    $admin_dialog->post()->to('admin-dialog#post');
    my $admin_dialog_item = $admin_dialog->route('/:dialog_id')->under->to('admin-dialog#stasher');

    # Admin::Dialog::Question.
    my $admin_dialog_item_question = $admin_dialog_item->route('/question');
    $admin_dialog_item_question->post()->to('admin-dialog-question#post');

    # Poll.
    my $poll      = $api->route('/poll');
    my $poll_item = $poll->route('/:poll_id')->under->to('poll#item_stasher');
    $poll->get()->to('poll#get');
    $poll_item->put()->to('poll#item_put');

    # Politician.
    my $politician_list = $api->route('/politician')->over(has_priv => 'politician');
    my $politician_result = $politician_list->route('/:politician_id')->under->to('politician#stasher');
    $politician_result->get()->to('politician#get');
    $politician_result->put()->to('politician#put');

    # Politician::Contact.
    my $politician_contact = $politician_result->route('/contact');
    $politician_contact->get()->to('politician-contact#get');
    $politician_contact->post()->to('politician-contact#post');

    # Politician::Greeting.
    my $politician_greeting = $politician_result->route('/greeting');
    $politician_greeting->get()->to('politician-greeting#get');
    $politician_greeting->post()->to('politician-greeting#post');

    # Politician::Answers.
    my $politician_answers = $politician_result->route('/answers');
    $politician_answers->get()->to('politician-answers#get');
    $politician_answers->post()->to('politician-answers#post');

    # Politician::DirectMessage
    my $direct_message = $politician_result->route('/direct-message');
    $direct_message->post->to('politician-direct_message#post');
    $direct_message->get->to('politician-direct_message#get');

    # Politician::Dashboard.
    my $politician_dashboard = $politician_result->route('/dashboard');
    $politician_dashboard->get()->to('politician-dashboard#get');

    # Politician::Groups.
    my $politician_groups = $politician_result->route('/group');
    $politician_groups->post()->to('politician-groups#post');

    # Politician::Groups::Count.
    $politician_groups->post('/count')->to('politician-groups-count#post');

    # Politician::VotoLegalIntegration
    my $politician_votolegal_integration = $politician_result->route('/votolegal-integration');
    $politician_votolegal_integration->post()->to('politician-voto_legal_integration#post');

    # Chatbot.
    my $chatbot = $api->route('/chatbot')->under->to('chatbot#validade_security_token');
    $chatbot->get()->to('chatbot#get');

    # Chatbot::Recipient.
    $chatbot->post('/recipient')->to('chatbot-recipient#post');

    # Chatbot::Issue.
    $chatbot->post('/issue')->to('chatbot-issue#post');

    # Chatbot::Politician
    my $chatbot_politician = $chatbot->route('/politician')->under->to('chatbot-politician#stasher');
    $chatbot_politician->get()->to('chatbot-politician#get');

    #"/api/politician/$politician_id/answers",
}

1;
