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
            entities       => encode_json(
                {
					"responseId" => "63f36f86-1379-4cd0-bf8d-d1932f29c5c4",
					"queryResult" => {
						"queryText" => "O que você acha sobre o aborto?",
						"parameters" => {
							"tipos_de_pergunta" => ["Proposta"],
                            "aborto"            => ["Aborto"]
						},
						"allRequiredParamsPresent" => 1,
						"fulfillmentMessages" => [
							{
								"text" => {
									"text" => [""]
								}
							}
						],
						"intent" => {
							"name" => "projects/marina-chatbot/agent/intents/e4ec7ee6-5624-47ea-ace9-5ed2a95255ce",
							"displayName" => "Aborto"
						},
						"intentDetectionConfidence" => 0.87,
						"languageCode" => "pt-br"
					}
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
					"responseId" => "63f36f86-1379-4cd0-bf8d-d1932f29c5c4",
					"queryResult" => {
						"queryText" => "Quais são suas propostas para a saude?",
						"parameters" => {
							"tipos_de_pergunta" => ["Proposta"],
							"saude"             => ["Saude"]
						},
						"allRequiredParamsPresent" => 1,
						"fulfillmentMessages" => [
							{
								"text" => {
									"text" => [""]
								}
							}
						],
						"intent" => {
							"name" => "projects/marina-chatbot/agent/intents/e4ec7ee6-5624-47ea-ace9-5ed2a95255ce",
							"displayName" => "Saude"
						},
						"intentDetectionConfidence" => 0.87,
						"languageCode" => "pt-br"
					}
				}
            )
        ]
    ;
    my $second_issue_id = stash "i2.id";

    api_auth_as user_id => $politician_id;

    my $question = fake_sentences(1)->();
    my $answer   = fake_sentences(2)->();

    my $politician_entity_rs = $schema->resultset('PoliticianEntity');

    my $first_entity  = $politician_entity_rs->search( { name => 'Saude' } )->next;
    my $second_entity = $politician_entity_rs->search( { name => 'Aborto' } )->next;

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

    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
            entities       => encode_json(
				{
					"responseId" => "63f36f86-1379-4cd0-bf8d-d1932f29c5c4",
					"queryResult" => {
						"queryText" => "Quais são suas propostas para os direitos dos animais?",
						"parameters" => {
							"tipos_de_pergunta"    => ["Proposta"],
							"direitos_dos_animais" => ["Direitos dos animais"]
						},
						"allRequiredParamsPresent" => 1,
						"fulfillmentMessages" => [
							{
								"text" => {
									"text" => [""]
								}
							}
						],
						"intent" => {
							"name" => "projects/marina-chatbot/agent/intents/e4ec7ee6-5624-47ea-ace9-5ed2a95255ce",
							"displayName" => "Saude"
						},
						"intentDetectionConfidence" => 0.87,
						"languageCode" => "pt-br"
					}
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
            entities       => encode_json(
				{
					"responseId" => "63f36f86-1379-4cd0-bf8d-d1932f29c5c4",
					"queryResult" => {
						"queryText" => "Quais são suas propostas para os direitos dos animais?",
						"parameters" => {
							"tipos_de_pergunta"    => ["Proposta"],
							"direitos_dos_animais" => ["Direitos dos animais"]
						},
						"allRequiredParamsPresent" => 1,
						"fulfillmentMessages" => [
							{
								"text" => {
									"text" => [""]
								}
							}
						],
						"intent" => {
							"name" => "projects/marina-chatbot/agent/intents/e4ec7ee6-5624-47ea-ace9-5ed2a95255ce",
							"displayName" => "privilegios_politicos"
						},
						"intentDetectionConfidence" => 0.87,
						"languageCode" => "pt-br"
					}
				}
            )
        ]
    ;

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 0, '0 rows' )
    }
};

done_testing();