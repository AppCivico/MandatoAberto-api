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

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

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

    rest_get "/api/politician/$politician_id/dashboard/new",
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

    # Testando role para módulo de métricas
    db_transaction{
        db_transaction{
            $schema->resultset('UserRole')->search(
                {
                    user_id => $politician_id,
                    role_id => 7
                }
            )->delete;

            rest_get "/api/politician/$politician_id/dashboard/new",
                name    => "politician dashboard without role",
                is_fail => 1,
                code    => 403
            ;
        };

        rest_get "/api/politician/$politician_id/dashboard/new",
            name => "politician dashboard with role",
        ;
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

    rest_put "/api/poll/$poll_id",
        name => 'Deactivating poll',
        [ status_id => 3 ]
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name                => 'politician greeting',
        automatic_load_item => 1,
        code                => 200,
        [
            on_facebook => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
            on_website  => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
        ]
    ;

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

    rest_post "/api/politician/$politician_id/answers",
        name  => "politician answer",
        code  => 200,
        [ "question[$question_id][answer]" => fake_words(1)->() ]
    ;

    $schema->resultset("UserSession")->create({
        user_id     => $politician_id,
        api_key     => fake_digits("##########")->(),
        created_at  => \'NOW()',
        valid_until => \'NOW()',
    });

    # Criando grupo
    $schema->resultset("Group")->create(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => 'foobar',
            filter                  => '{}',
            recipients_count        => 1
        }
    );

    my $issue = $schema->resultset('Issue')->find($issue_id);
    $issue->update(
        {
            reply => 'foobar',
            updated_at => \"NOW() + interval '1 hour'"
        }
    );

    subtest 'Politician | Dashboard (new)' => sub {
        rest_get "/api/politician/$politician_id/dashboard/new",
            name  => 'get new dashboard',
            stash => 'd2',
            list  => 1,
            [ range => 7 ]
        ;

        stash_test 'd2' => sub {
            my $res = shift;

            is( ref $res->{metrics},                     'ARRAY', 'metrics is an array' );
            is( ref $res->{metrics}->[0]->{sub_metrics}, 'ARRAY', 'sub_metrics is an array' );
            ok( defined $res->{metrics}->[0]->{count}, 'count is defined' );
            ok( defined $res->{metrics}->[0]->{text}, 'text is defined' );
            ok( defined $res->{metrics}->[0]->{name}, 'name is defined' );
        }
    };

	my $res = rest_get "/api/politician/$politician_id/dashboard",
	  name  => 'get new dashboard',
	  stash => 'd2',
	  list  => 1;
};

done_testing();
