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

    my $recipient_fb_id = 'foobar';
    rest_post "/api/chatbot/recipient",
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

    my $issue = $schema->resultset("Issue")->find(stash "i1.id");

    is ( $politician->politician_entities->count, 1, 'one politician entity' );
    ok ( my $politician_entity = $politician->politician_entities->next, 'politician entity' );
    is ( $politician_entity->recipient_count, 1,           'recipient count' );

    ok ($issue->open eq '1', 'Issue is created as open');

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
};

done_testing();