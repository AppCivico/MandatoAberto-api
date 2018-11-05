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
                            intentName                => 'Aborto'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
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
                            intentName                => 'Saude'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
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

    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
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
                            intentName                => 'Saude'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
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
                            intentName                => 'privilegios_politicos'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
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
            entities       => 'Saude'
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
                entities       => 'Saude'
            ]
        ;

        stash_test 'get_knowledge_base_new_model' => sub {
            my $res = shift;

            is ( scalar @{ $res->{knowledge_base} }, 2, '2 rows' )
        };
    };
};

done_testing();