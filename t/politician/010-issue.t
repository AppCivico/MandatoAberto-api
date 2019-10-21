use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    my $issue_rs = $schema->resultset('Issue');

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset('Politician')->find($politician_id);

    rest_get "/api/politician/$politician_id/issue",
        name    => "get issues without login",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
        [
            origin_dialog  => fake_words(1)->(),
            politician_id  => $politician_id,
            name           => fake_name()->(),
            fb_id          => $recipient_fb_id,
            email          => fake_email()->(),
            cellphone      => fake_digits("+551198#######")->(),
            gender         => fake_pick( qw/F M/ )->(),
            security_token => $security_token
        ]
    ;

    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => $message,
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
    my $first_issue_id = stash "i1.id";
    my $first_issue    = $issue_rs->find($first_issue_id);

    api_auth_as "user_id" => $politician_id;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name => "reading an issue",
        [ read => 1 ]
    ;

    rest_get "/api/politician/$politician_id/issue",
        name  => "get issues",
        list  => 1,
        stash => "get_issues",
        [ filter => 'all' ]
    ;

    stash_test "get_issues" => sub {
        my $res = shift;

        ok( defined $res->{itens_count}, 'itens_count is defined' );

        is ($res->{issues}->[0]->{message}, $message, 'issue message');
        is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
        is ($res->{issues}->[0]->{updated_at}, undef, 'issue updated timestamp');
        is ($res->{issues}->[0]->{read}, 1, 'issue was read');
    };

    # Testando issue com conteúdo "Participar"
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i9",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => 'Participar',
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
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
    my $second_issue_id = stash "i2.id";
    my $second_issue    = $issue_rs->find($second_issue_id);

    # Testando batch delete de issues
    db_transaction{
        $first_issue->update( { reply => undef } );
        $second_issue->update( { reply => undef } );

        $first_issue  = $first_issue->discard_changes;
        $second_issue = $second_issue->discard_changes;

        rest_put "/api/politician/$politician_id/issue/batch-delete",
          name    => 'batch delete without ids',
          is_fail => 1,
          code    => 400;

        rest_put "/api/politician/$politician_id/issue/batch-delete",
          name => 'batch delete',
          code => 200,
          [ ids => "$first_issue_id, $second_issue_id" ];

        rest_get "/api/politician/$politician_id/issue",
          name  => 'get deleted issues',
          stash => 'get_deleted_issues',
          list  => 1,
          [ filter => 'deleted' ];

        stash_test 'get_deleted_issues' => sub {
            my $res = shift;

            is( scalar @{ $res->{issues} }, 2, '2 issues' );
          }
    };

    # Criando um grupo para adicionar o recipiente
    # no fechamento da segunda issue
    my $group = $schema->resultset("Group")->create(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => 'foobar',
            filter                  => '{}',
            status                  => 'ready',
            recipients_count        => 0
        }
    );

    my $group_id = $group->id;

    # Fechando uma issue e segmentando o recipient
    rest_put "/api/politician/$politician_id/issue/$second_issue_id",
        name => "updating issue without reply",
        [
            ignore => 0,
            groups => "[$group_id]",
            reply  => fake_words(1)->()
        ]
    ;

    is ($group->discard_changes->recipients_count, 1, 'one recipient on group');

    # Respondendo issue com mídia
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i3",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
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
    my $third_issue_id = stash "i3.id";

    rest_put "/api/politician/$politician_id/issue/$third_issue_id",
        name  => "updating issue with media",
        files => { file => "$Bin/picture.jpg", },
    ;

    my $third_issue    = $issue_rs->find($third_issue_id);
    ok ( defined( $third_issue->saved_attachment_id ), 'defined' );
};

done_testing();
