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
