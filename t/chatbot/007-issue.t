use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => 'foo',
    );
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my $recipient_fb_id = 'foobar';
    my $res = rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'c1',
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

    my $recipient_id = $res->{id};

    rest_post "/api/chatbot/issue",
        name    => 'issue without message',
        is_fail => 1,
        code    => 400,
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without politician_id',
        is_fail => 1,
        code    => 400,
        [
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without fb_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id  => $politician_id,
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without matching politician_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id  => fake_words(1)->(),
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without matching fb_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id  => $politician_id,
            fb_id          => fake_words(1)->(),
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
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
        ],
    ;

    my $issue = $schema->resultset("Issue")->find(stash "i1.id");

    is ( $politician->user->organization_chatbot->politician_entities->count, 1, 'one politician entity' );
    ok ( my $politician_entity = $politician->user->organization_chatbot->politician_entities->next, 'politician entity' );
    is ( $politician_entity->recipient_count, 1,           'recipient count' );

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
        ],
    ;

    $issue = $schema->resultset("Issue")->find(stash "i2.id");

    ok ($issue->peding_entity_recognition eq '1', 'Issue needs to be recognized');

    # Creating issue with empty entities object
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i3",
        [
            entities       => '{}',
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
        ],
    ;

    # Creating issue with recipient_id
    rest_post "/api/chatbot/issue",
        name                => "issue creation with recipient_id",
        automatic_load_item => 0,
        stash               => "i4",
        [
            entities       => '{}',
            politician_id  => $politician_id,
            recipient_id   => $recipient_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
        ],
    ;
};

done_testing();
