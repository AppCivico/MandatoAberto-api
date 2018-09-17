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
							"displayName" => "direitos_animais"
						},
						"intentDetectionConfidence" => 0.87,
						"languageCode" => "pt-br"
					}
				}
            )
        ],
    ;

    my $politician_entity = $schema->resultset('PoliticianEntity')->search( { politician_id => $politician_id } )->next;
    my $politician_entity_id = $politician_entity->id;

    api_auth_as user_id => $politician_id;

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
    };

    # Listando entidades sem nenhum posiocionamento
    rest_get "/api/politician/$politician_id/intent/pending",
        name  => 'get pending entities',
        stash => 'get_pending_entities',
        list  => 1
    ;
};

done_testing();