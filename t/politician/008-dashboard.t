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
        stash               => 'i1',
        [
            politician_id  => $politician_id,
            fb_id          => 'foobar',
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
				{
					id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
					timestamp => '2018-09-19T21 => 39 => 43.452Z',
					lang      => 'pt-br',
					result    => {
						source           => 'agent',
						resolvedQuery    => 'O que você acha do aborto?',
						action           => '',
						actionIncomplete => 0,
						parameters       => {},
						contexts         => [],
						metadata         => {
							intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
							webhookUsed               => 0,
							webhookForSlotFillingUsed => 0,
							isFallbackIntent          => 0,
							intentName                => 'direitos_animais'
						},
						fulfillment => { speech =>  '', messages =>  [] },
						score       => 1
					},
					status    => { code =>  200, errorType =>  'success' },
					sessionId => '1938538852857638'
				}
            )
        ]
    ;
    my $issue_id = stash 'i1.id';

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

    # rest_get "/api/politician/$politician_id/dashboard",
    #     name    => "invalid data range",
    #     is_fail => 1,
    #     code    => 400,
    #     [ range => 5 ]
    # ;

    # rest_get "/api/politician/$politician_id/dashboard",
    #     name    => "invalid data range",
    #     is_fail => 1,
    #     code    => 400,
    #     [ range => 'foobar' ]
    # ;

    # rest_get "/api/politician/$politician_id/dashboard",
    #     name    => "valid data range",
    #     [ range => 16 ]
    # ;

    rest_get "/api/politician/$politician_id/dashboard",
        name  => "politician dashboard",
        list  => 1,
        stash => "get_politician_dashboard"
    ;

    stash_test "get_politician_dashboard" => sub {
        my $res = shift;

        is ($res->{recipients}->{count}, 1, 'one citizen');
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

        is ($res->{recipients}->{count}, 2, 'two citizens');
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

        is ($res->{recipients}->{count}, 2, 'two citizens');
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
        [
            on_facebook => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
            on_website  => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
        ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{recipients}->{count}, 2, 'two citizens');
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

        is ($res->{recipients}->{count}, 2, 'two citizens');
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

        is ($res->{recipients}->{count}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 1, 'politician has dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician does have facebook auth');
    };

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{recipients}->{count}, 2, 'two citizens');
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
            politician_id    => $politician_id,
            name             => 'foobar',
            filter           => '{}',
            recipients_count => 1
        }
    );

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{recipients}->{count}, 2, 'two citizens');
        is ($res->{has_greeting}, 1, 'politician has greeting');
        is ($res->{has_contacts}, 1, 'politician has contacts');
        is ($res->{has_dialogs}, 1, 'politician has dialogs');
        is ($res->{has_facebook_auth}, 1, 'politician has facebook auth');
        is ($res->{first_access}, 0, 'politician first access');
        is ($res->{groups}->{count}, 1, 'group count');
        is ($res->{issues}->{count_open}, 1, 'open issues count');
        is ($res->{issues}->{count_open_last_24_hours}, 1, 'open issues count');
    };

    my $issue = $schema->resultset('Issue')->find($issue_id);
    $issue->update(
        {
            reply => 'foobar',
            open  => 0,
            updated_at => \"NOW() + interval '1 hour'"
        }
    );

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ( $res->{issues}->{avg_response_time}, '60', '60 minutes avg response time' );
    };
};

done_testing();