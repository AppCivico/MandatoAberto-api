use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician    = $schema->resultset('Politician')->find(stash 'politician.id');
    my $politician_id = $politician->id;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

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

    my $politician_entity = $schema->resultset('PoliticianEntity')->search( { organization_chatbot_id => $organization_chatbot_id } )->next;
    my $politician_entity_id = $politician_entity->id;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            entity_id => $politician_entity_id,
            answer    => 'foobar',
            type      => 'posicionamento'
        ]
    ;
    my $kb_id = stash 'k1.id';

    rest_get "/api/politician/$politician_id/intent",
        name  => 'get entities',
        stash => 'get_entities',
        list  => 1
    ;

    stash_test 'get_entities' => sub {
        my $res = shift;
        is ( ref $res->{politician_entities}, 'ARRAY', 'expected array' );
        ok ( my $politician_entity_res = $res->{politician_entities}->[0], 'politician entity' );
        is ( ref $res->{politician_entities}, 'ARRAY', 'expected array' );

    };

    rest_get "/api/politician/$politician_id/intent/$politician_entity_id",
        name  => 'get entity result',
        stash => 'get_entity_result',
        list  => 1,
    ;

    stash_test 'get_entity_result' => sub {
        my $res = shift;

        ok ( my $recipient_res = $res->{recipients}->[0], 'recipient ok' );
        is ( $recipient_res->{id}, $recipient->id, 'recipient id' );

        ok( ref $res->{knowledge_base} eq 'ARRAY',                         'pending_types is an array' );
        is( scalar @{ $res->{knowledge_base} },    3,                      'pending_types has 3 entries' );
        is( $res->{recipient_count},               1,                      'one recipient' );
        #is( $res->{tag},                           'direitos dos animais', 'human name' );
    };

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k2',
        [
            entity_id => $politician_entity_id,
            answer    => 'bazbar',
            type      => 'proposta'
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            entity_id => $politician_entity_id,
            answer    => 'quux',
            type      => 'histórico'
        ]
    ;
};

done_testing();
