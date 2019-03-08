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
        ],
    ;

    my $issue = $schema->resultset("Issue")->find(stash "i1.id");

    is ( $politician->user->organization_chatbot->politician_entities->count, 1, 'one politician entity' );
    ok ( my $politician_entity = $politician->user->organization_chatbot->politician_entities->next, 'politician entity' );
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
};

done_testing();