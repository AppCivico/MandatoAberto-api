use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    api_auth_as user_id => 1;

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

     ok my $dialog = $schema->resultset('OrganizationDialog')->create(
        {
            organization_id => $politician->user->organization->id,
            name            => 'foobar',
            description     => 'foobar'
        }
    );
    my $dialog_id = $dialog->id;

    ok my $question = $schema->resultset('OrganizationQuestion')->create(
        {
            organization_dialog_id => $dialog->id,
            name                   => fake_words(1)->(),
            content                => fake_words(1)->(),
            citizen_input          => fake_words(1)->()
        }
    );
    my $question_id = $question->id;

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
    "responseId" => "f51c7faf-7569-425c-898e-f1130f17960b-7e4f1f27",
    "queryResult" => {
        "fulfillmentMessages" => [
            {
                "platform" => "PLATFORM_UNSPECIFIED",
                "text" => {
                    "text" => ["Lamento, mas não compreendi."]
                },
                "message" => "text"
            }
        ],
        "outputContexts" => [],
        "queryText" => "O que você acha do aborto?",
        "speechRecognitionConfidence" => 0,
        "action" => "input.unknown",
        "parameters" => {
            "fields" => {}
        },
        "allRequiredParamsPresent" => 1,
        "fulfillmentText" => "Lamento, mas não compreendi.",
        "webhookSource" => "",
        "webhookPayload" => undef,
        "intent" => {
            "inputContextNames" => [],
            "events" => [],
            "trainingPhrases" => [],
            "outputContexts" => [],
            "parameters" => [],
            "messages" => [],
            "defaultResponsePlatforms" => [],
            "followupIntentInfo" => [],
            "name" => "projects/dipiou-eivcjk/agent/intents/1f450a68-c73f-4419-8366-3c8b6fb4299a",
            "displayName" => "direitos_animais",
            "priority" => 0,
            "isFallback" => 1,
            "webhookState" => "WEBHOOK_STATE_UNSPECIFIED",
            "action" => "",
            "resetContexts" => 0,
            "rootFollowupIntentName" => "",
            "parentFollowupIntentName" => "",
            "mlDisabled" => 0
        },
        "intentDetectionConfidence" => 1,
        "diagnosticInfo" => undef,
        "languageCode" => "pt-br"
    },
    "webhookStatus" => undef
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
