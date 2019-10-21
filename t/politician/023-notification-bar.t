use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use DateTime;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;

    rest_put "/api/politician/$politician_id",
        name => 'activate chatbot',
        [
            fb_page_id           => 'foobar',
            fb_page_access_token => 'foobarz'
        ]
    ;

    create_recipient( politician_id => $politician_id );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    # Criando a entidade
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
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

    rest_get "/api/politician/$politician_id/notification-bar",
        name  => 'get notification bar',
        stash => 'get_notification_bar',
        list  => 1
    ;

    stash_test 'get_notification_bar' => sub {
        my $res = shift;

    }
};

done_testing();