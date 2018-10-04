use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;
use Mojo::JSON qw(encode_json);

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    api_auth_as user_id => 1;

    my $dialog = create_dialog;
    my $dialog_id = $dialog->{id};

    $t->post_ok(
        "/api/admin/dialog/$dialog_id/question",
        form => {
            name          => 'foobar',
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        },
    )
    ->status_is(201);

    ok my $question_id = $t->tx->res->json->{id};

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    ok my $politician_id = $politician->{id};

    $t->post_ok(
        "/api/chatbot/recipient",
        form => {
            name           => fake_name()->(),
            fb_id          => "foobar",
            origin_dialog  => fake_words(1)->(),
            gender         => fake_pick( qw/M F/ )->(),
            cellphone      => fake_digits("+551198#######")->(),
            email          => fake_email()->(),
            politician_id  => $politician_id,
            security_token => $security_token
        }
    )
    ->status_is(201);

    ok my $recipient_id = $t->tx->res->json->{id};

    # Criando uma issue.
    ok my $recipient = $schema->resultset("Recipient")->find($recipient_id);

    $t->post_ok(
        "/api/chatbot/issue",
        form => {
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
        }
    )
    ->status_is(201);

    ok my $issue_id = $t->tx->res->json->{id};

    subtest 'Politician | dashboard' => sub {

        api_auth_as user_id => 1;
        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(403);

        api_auth_as user_id => $politician_id;

        $t->post_ok(
            "/api/register/poll",
            form => {
                'name'                     => 'foobar',
                'status_id'                => 1,
                'questions[0]'             => 'Você está bem?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
                'questions[1][options][2]' => 'não',
            }
        )
        ->status_is(201);

        ok my $poll_id = $t->tx->res->json->{id};

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 1, 'recipients_count=1');

        $t->post_ok(
            "/api/chatbot/recipient",
            form => {
                name           => fake_name()->(),
                fb_id          => "FOOBAR",
                origin_dialog  => fake_words(1)->(),
                gender         => fake_pick( qw/M F/ )->(),
                cellphone      => fake_digits("+551198#######")->(),
                email          => fake_email()->(),
                politician_id  => $politician_id,
                security_token => $security_token
            }
        )
        ->status_is(201);

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients'->{count}, 2, 'two citizens')
        ->json_is('/has_greeting',        0, 'politician does not have greeting')
        ->json_is('/has_contacts',        0, 'politician does not have contacts')
        ->json_is('/has_dialogs',         0, 'politician does not have dialogs')
        ->json_is('/has_active_poll',     1, 'politician has active poll')
        ->json_is('/has_facebook_auth',   1, 'politician does have facebook auth');

        $t->put_ok(
            "/api/poll/$poll_id",
            form => { status_id => 3 }
        )
        ->status_is(202);

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 2, 'two citizens')
        ->json_is('/has_greeting', 0, 'politician does not have greeting')
        ->json_is('/has_contacts', 0, 'politician does not have contacts')
        ->json_is('/has_dialogs', 0, 'politician does not have dialogs')
        ->json_is('/has_active_poll', 0, 'politician does not have active poll')
        ->json_is('/ever_had_poll', 1, 'politician has at least one poll')
        ->json_is('/has_facebook_auth', 1, 'politician does  have facebook auth');

        $t->post_ok(
            "/api/politician/$politician_id/greeting",
            form => {
                on_facebook => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
                on_website  => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
            }
        )
        ->status_is(201);

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 2, 'two citizens')
        ->json_is('/has_greeting', 1, 'politician has greeting')
        ->json_is('/has_contacts', 0, 'politician does not have contacts')
        ->json_is('/has_dialogs', 0, 'politician does not have dialogs')
        ->json_is('/has_facebook_auth', 1, 'politician does have facebook auth');

        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                twitter  => '@lucas_ansei',
                facebook => 'https://facebook.com/lucasansei',
                email    => 'foobar@email.com',
            }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 2, 'two citizens')
        ->json_is('/has_greeting', 1, 'politician has greeting')
        ->json_is('/has_contacts', 1, 'politician has contacts')
        ->json_is('/has_dialogs', 0, 'politician does not have dialogs')
        ->json_is('/has_facebook_auth', 1, 'politician does have facebook auth');

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$question_id][answer]" => fake_words(1)->() }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 2, 'two citizens')
        ->json_is('/has_greeting', 1, 'politician has greeting')
        ->json_is('/has_contacts', 1, 'politician has contacts')
        ->json_is('/has_dialogs',  1, 'politician has dialogs')
        ->json_is('/has_facebook_auth', 1, 'politician does have facebook auth')
        ->json_is('/first_access',      1, 'politician first access');

        ok $schema->resultset('UserSession')->create({
            user_id     => $politician_id,
            api_key     => fake_digits("##########")->(),
            created_at  => \'NOW()',
            valid_until => \'NOW()',
        });

        # Criando grupo
        ok $schema->resultset("Group")->create(
            {
                politician_id    => $politician_id,
                name             => 'foobar',
                filter           => '{}',
                recipients_count => 1
            }
        );

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/recipients/count', 2, 'two citizens')
        ->json_is('/has_greeting', 1, 'politician has greeting')
        ->json_is('/has_contacts', 1, 'politician has contacts')
        ->json_is('/has_dialogs', 1, 'politician has dialogs')
        ->json_is('/has_facebook_auth', 1, 'politician has facebook auth')
        ->json_is('/first_access', 0, 'politician first access')
        ->json_is('/groups/count', 1, 'group count')
        ->json_is('/issues/count_open', 1, 'open issues count')
        ->json_is('/issues/count_open_last_24_hours', 1, 'open issues count');

        ok my $issue = $schema->resultset('Issue')->find($issue_id);
        ok $issue->update(
            {
                reply => 'foobar',
                open  => 0,
                updated_at => \"NOW() + interval '1 hour'"
            }
        );

        $t->get_ok("/api/politician/$politician_id/dashboard")
        ->status_is(200)
        ->json_is('/issues/avg_response_time', 60, 'avg_response_time=60');
    };
};

done_testing();