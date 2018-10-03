package MandatoAberto::Routes;
use strict;
use warnings;

sub register {
    my $r = shift;

    my $api = $r->route('/api');

    # Register.
    my $register = $api->route('/register');
    $register->post('/politician')->to('register-politician#post');

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

    # Politician.
    my $politician_list = $api->route('/politician')->over(has_priv => 'politician');
    my $politician_result = $politician_list->route('/:politician_id')->under->to('politician#stasher');
    $politician_result->get->to('politician#get');
    $politician_result->put->to('politician#put');

    # Politician::Contact.
    my $politician_contact = $politician_result->route('/contact');
    $politician_contact->get->to('politician-contact#get');
    $politician_contact->post->to('politician-contact#post');

    # Politician::Greeting.
    my $politician_greeting = $politician_result->route('/greeting');
    $politician_greeting->get->to('politician-greeting#get');
    $politician_greeting->post->to('politician-greeting#post');
}

1;
