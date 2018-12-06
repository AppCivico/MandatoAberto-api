use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset('Politician')->find($politician_id);

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

	my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
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
    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => $message,
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
    my $issue_id = stash "i1.id";

    my $politician_entity_id = $schema->resultset('PoliticianEntity')->search(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => 'saude'
        }
    )->next->id;

    my $question = fake_sentences(1)->();
    my $answer   = fake_sentences(2)->();

    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry with invalid entity_id',
        is_fail => 1,
        code    => 400,
        [
            entity_id => 9999999,
            answer    => $answer,
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            entity_id => $politician_entity_id,
            answer    => $answer,
            type      => 'posicionamento'
        ]
    ;
    my $kb_id = stash 'k1.id';

    rest_get "/api/politician/$politician_id/knowledge-base",
        name  => 'get politician knowledge base entry (list)',
        stash => 'get_knowledge_base',
        list  => 1
    ;

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} },    1,       'one item in the array' );
        is ( $res->{knowledge_base}->[0]->{id},     $kb_id,  'kb id' );
        is ( $res->{knowledge_base}->[0]->{answer}, $answer, 'kb answer' );
    };

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            entity_id => $politician_entity_id,
            answer    => 'upsert',
            type      => 'posicionamento'
        ]
    ;

    rest_reload_list 'get_knowledge_base';
    stash_test 'get_knowledge_base.list' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} },    1,        'one item in the array' );
        is ( $res->{knowledge_base}->[0]->{id},     $kb_id,   'kb id' );
        is ( $res->{knowledge_base}->[0]->{answer}, 'upsert', 'kb answer' );
    };

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        [
            entity_id => $politician_entity_id,
            answer    => $answer,
            type      => 'posicionamento'
        ]
    ;

    rest_get "/api/politician/$politician_id/knowledge-base/$kb_id",
        name  => 'get politician knowledge base entry (result)',
        stash => 'get_knowledge_base_entry',
        list  => 1,
    ;

    stash_test 'get_knowledge_base_entry' => sub {
        my $res = shift;

        my $issues   = $res->{issues};
        my $entities = $res->{intents};

        is ( $res->{active},             1,                     'is active' );
        is ( $res->{answer},             $answer,               'answer' );
        is ( defined $res->{created_at}, 1,                     'created_at is defined' );
        is ( ref $entities,              'ARRAY',               'entities is an array' );
        is ( $entities->[0]->{id},       $politician_entity_id, 'entity id' );
        is ( ref $res->{type},           '',                    'type is a string' );
        is ( $res->{type},               'posicionamento',      'kb is of posicionamento type' );
    };

    rest_put "/api/politician/$politician_id/knowledge-base/$kb_id",
        name => 'update politician knowledge base entry',
        [
            active   => 0,
            answer   => 'foobar',
        ]
    ;

    rest_reload_list 'get_knowledge_base_entry';

    stash_test 'get_knowledge_base_entry.list' => sub {
        my $res = shift;

        is ( $res->{active},             0,                    'not active' );
        is ( $res->{answer},             'foobar',             'updated answer' );
        is ( defined $res->{updated_at}, 1,                    'updated_at is defined' );

        is ( $res->{intents}->[0]->{recipients_count}, 1, 'one recipient' );
    };

    rest_put "/api/politician/$politician_id/knowledge-base/$kb_id",
        name => 'update politician knowledge base entry',
        [ type => 'Proposta' ]
    ;


    rest_reload_list 'get_knowledge_base_entry';

    stash_test 'get_knowledge_base_entry.list' => sub {
        my $res = shift;

        is( $res->{type}, 'proposta', '"Proposta" type' );
    };

    # Listando entidades sem nenhum posiocionamento
    rest_get "/api/politician/$politician_id/intent/pending",
        name  => 'get pending entities',
        stash => 'get_pending_entities',
        list  => 1
    ;

    # stash_test 'get_pending_entities' => sub {
    #     my $res = shift;

    #     is ( $res->{politician_entities}->[0]->{id},  $politician_entity_id, 'entity id' );
    #     is ( $res->{politician_entities}->[0]->{tag}, 'Saude',               'entity name' );
    # };

    # rest_put "/api/politician/$politician_id/knowledge-base/$kb_id",
    #     name => 'update politician knowledge base entry',
    #     [ active => 1 ]
    # ;

    # rest_reload_list 'get_pending_entities';

    # stash_test 'get_pending_entities.list' => sub {
    # 	my $res = shift;

    #     is ( scalar @{ $res->{politician_entities} }, 0, 'empty array' );
    # };

    # rest_post "/api/chatbot/issue",
    #     name                => "issue creation",
    #     automatic_load_item => 0,
    #     stash               => "i2",
    #     [
    #         politician_id  => $politician_id,
    #         fb_id          => $recipient_fb_id,
    #         message        => $message,
    #         security_token => $security_token,
    #         entities       => encode_json( { Aborto => [ 'aborto' ] } )
    #     ]
    # ;

    # rest_reload_list 'get_pending_entities';

    # stash_test 'get_pending_entities.list' => sub {
    # 	my $res = shift;

    # 	is( scalar @{ $res->{politician_entities} }, 1, 'one row' );
    # };

    # rest_put "/api/politician/$politician_id/knowledge-base/$kb_id",
    #     name => 'update politician knowledge base entry',
    #     [ active => 0 ]
    # ;

    # rest_reload_list 'get_pending_entities';

    # stash_test 'get_pending_entities.list' => sub {
    # 	my $res = shift;

    # 	is( scalar @{ $res->{politician_entities} }, 2, 'two rows' );
    # };

};

done_testing();