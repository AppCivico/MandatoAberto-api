use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    $politician       = $schema->resultset('Politician')->find( $politician->{id} );
    my $politician_id = $politician->id;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    create_recipient( politician_id => $politician_id );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    # Criando entrada de knowledge-base
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
            message        => 'Como faço para me vacinar?',
            security_token => $security_token,
            entities => encode_json(
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
							"queryText" => "teste teste teste",
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
								"displayName" => "Aborto",
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
    my $issue_id = stash "i1.id";

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
            message        => 'O que você acha sobre o aborto?',
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
							"displayName" => "Saude",
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

    api_auth_as user_id => $politician_id;

    my $question = fake_sentences(1)->();
    my $answer   = fake_sentences(2)->();

    my $politician_entity_rs = $schema->resultset('PoliticianEntity');

    my $first_entity  = $politician_entity_rs->search( { name => 'saude' } )->next;
    my $second_entity = $politician_entity_rs->search( { name => 'aborto' } )->next;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry (Saude - posicionamento)',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            entity_id => $first_entity->id,
            answer    => 'foobar',
            type      => 'posicionamento'
        ],
    ;


    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry (Saude - proposta)',
        automatic_load_item => 0,
        stash               => 'k3',
        [
            entity_id => $first_entity->id,
            answer    => 'foobarz',
            type      => 'proposta'
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name  => 'creating knowledge base entry (ABORTO - posicionamento)',
        stash => 'k2',
        [
            entity_id => $second_entity->id,
            answer    => 'posicionamento sobre o aborto',
            type      => 'posicionamento'
        ]
    ;

    # fb_id is required
    rest_get '/api/chatbot/knowledge-base',
        name    => 'get kb without fb_id',
        is_fail => 1,
        code    => 400,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
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
							"displayName" => "Saude",
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

    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
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
                            "displayName" => "Saude",
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

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 2, '2 rows' );

        ok ( defined $res->{knowledge_base}->[0]->{answer},   'answer is defined' );
        ok ( ref $res->{knowledge_base}->[0]->{answer} eq '', 'answer is a string' );
        ok ( defined $res->{knowledge_base}->[0]->{type},     'type is defined' );
        ok ( ref $res->{knowledge_base}->[0]->{type} eq '',   'type is a string' );
        ok ( ref $res->{knowledge_base}->[0]->{type} eq '',   'type is a string' );
    };

    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base with no knowledge base registered for that entity',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
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
							"displayName" => "privilegios_politicos",
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

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 0, '0 rows' )
    };

    # Testando knowledge base com apenas a string do tema
    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base with no knowledge base registered for that entity',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
            entities       => 'Saude',
            fb_id          => $recipient->fb_id
        ]
    ;

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 2, '2 rows' )
    };

    subtest 'Chatbot | Get knowledge base (new model)' => sub {
        rest_get "/api/chatbot/politician/$politician_id/knowledge-base",
            name  => 'get knowledge base new model',
            stash => 'get_knowledge_base_new_model',
            list  => 1,
            [
                security_token => $security_token,
                politician_id  => $politician_id,
                entities       => 'Saude',
                fb_id          => $recipient->fb_id
            ]
        ;

        stash_test 'get_knowledge_base_new_model' => sub {
            my $res = shift;

            is ( scalar @{ $res->{knowledge_base} }, 2, '2 rows' )
        };
    };

    # Criando um novo recipient
    # E mandando pergunta sobre um tema
    # Para testar a vinculação pelo GET do posicionamento
    subtest 'Chatbot | Get knowledge base' => sub {
        create_recipient(politician_id => $politician_id);
        $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');
        $recipient->update( { fb_id => 'foo' } );

        my $intent = $schema->resultset('PoliticianEntity')->search( { name => 'saude' } )->next;
        is( $intent->recipient_count, 1, 'one recipient' );

        rest_get '/api/chatbot/knowledge-base',
            name  => 'get knowledge base with no knowledge base registered for that entity',
            stash => 'get_knowledge_base',
            list  => 1,
            [
                security_token => $security_token,
                politician_id  => $politician_id,
                entities       => 'Saude',
                fb_id          => $recipient->fb_id
            ]
        ;

        ok( $intent = $intent->discard_changes );
        is( $intent->recipient_count, 2, 'one recipient' );

    };
};

done_testing();
