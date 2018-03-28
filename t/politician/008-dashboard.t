use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    api_auth_as user_id => 1;

    create_dialog;
    my $dialog_id = stash "dialog.id";

    rest_post "/api/admin/dialog/$dialog_id/question",
        name                => "Creating question",
        stash               => "q1",
        automatic_load_item => 0,
        [
            name          => 'foobar',
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;
    my $question_id = stash "q1.id";

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/recipient",
        name                => "Create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
        [
            name           => fake_name()->(),
            fb_id          => "foobar",
            origin_dialog  => fake_words(1)->(),
            gender         => fake_pick( qw/M F/ )->(),
            cellphone      => fake_digits("+551198#######")->(),
            email          => fake_email()->(),
            politician_id  => $politician_id,
            security_token => $security_token
        ]
    ;

    # Criando uma issue
    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

    rest_post "/api/chatbot/issue",
        name                => 'creating issue',
        automatic_load_item => 0,
        [
            politician_id  => $politician_id,
            fb_id          => 'foobar',
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;

    api_auth_as user_id => 1;

    rest_get "/api/politician/$politician_id/dashboard",
        name    => "get dashboard as admin",
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => 'foobar',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;
    my $poll_id = stash "p1.id";

    rest_get "/api/politician/$politician_id/dashboard",
        name    => "invalid data range",
        is_fail => 1,
        code    => 400,
        [ range => 5 ]
    ;

    rest_get "/api/politician/$politician_id/dashboard",
        name    => "invalid data range",
        is_fail => 1,
        code    => 400,
        [ range => 'foobar' ]
    ;

    rest_get "/api/politician/$politician_id/dashboard",
        name    => "valid data range",
        [ range => 16 ]
    ;

    rest_get "/api/politician/$politician_id/dashboard",
        name  => "politician dashboard",
        list  => 1,
        stash => "get_politician_dashboard"
    ;

    stash_test "get_politician_dashboard" => sub {
        my $res = shift;

        is ($res->{citizens}, 1, 'one citizen');
    };

    rest_post "/api/chatbot/recipient",
        name                => "Create recipient",
        automatic_load_item => 0,
        [
            name           => fake_name()->(),
            fb_id          => "FOOBAR",
            origin_dialog  => fake_words(1)->(),
            gender         => fake_pick( qw/M F/ )->(),
            cellphone      => fake_digits("+551198#######")->(),
            email          => fake_email()->(),
            politician_id  => $politician_id,
            security_token => $security_token
        ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 0, 'politician does not have greeting');
        is ($res->{has_contacts}, 0, 'politician does not have contacts');
        is ($res->{has_dialogs}, 0, 'politician does not have dialogs');
        is ($res->{has_active_poll}, 1, 'politician has active poll');
        is ($res->{has_facebook_auth}, 1, 'politician does have facebook auth');
    };

    rest_put "/api/poll/$poll_id",
        name => 'Deactivating poll',
        [ status_id => 3 ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 0, 'politician does not have greeting');
        is ($res->{has_contacts}, 0, 'politician does not have contacts');
        is ($res->{has_dialogs}, 0, 'politician does not have dialogs');
        is ($res->{has_active_poll}, 0, 'politician does not have active poll');
        is ($res->{ever_had_poll}, 1, 'politician has at least one poll');
        is ($res->{has_facebook_auth}, 1, 'politician does  have facebook auth');
    };

    rest_post "/api/politician/$politician_id/greeting",
        name                => 'politician greeting',
        automatic_load_item => 1,
        code                => 200,
        [ greeting_id => 1 ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 0, 'politician does not have contacts');
        is ($res->{has_dialogs}, 0, 'politician does not have dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician does have facebook auth');
    };

    rest_post "/api/politician/$politician_id/contact",
        name                => "politician contact",
        automatic_load_item => 0,
        code                => 200,
        [
            twitter  => '@lucas_ansei',
            facebook => 'https://facebook.com/lucasansei',
            email    => 'foobar@email.com',

        ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 0, 'politician does not have dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician does have facebook auth');
    };

    rest_post "/api/politician/$politician_id/answers",
        name  => "politician answer",
        code  => 200,
        [ "question[$question_id][answer]" => fake_words(1)->() ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 1, 'politician has dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician does have facebook auth');
    };

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 1, 'politician has dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician has facebook auth');
        is ($res->{first_access}, 1, 'politician first access');
    };

    $schema->resultset("UserSession")->create({
        user_id     => $politician_id,
        api_key     => fake_digits("##########")->(),
        created_at  => \'NOW()',
        valid_until => \'NOW()',
    });

    # Criando grupo
    $schema->resultset("Group")->create(
        {
            politician_id => $politician_id,
            name          => 'foobar',
            filter        => '{}',
        }
    );

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 1, 'politician has dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician has facebook auth');
        is ($res->{first_access}, 0, 'politician first access');
        is ($res->{group_count}, 1, 'group count');
        is ($res->{open_issue_count}, 1, 'open issues count');
    };
};

done_testing();