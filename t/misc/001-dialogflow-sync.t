use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $politician    = create_politician;
    my $politician_id = $politician->{id};

    api_auth_as user_id => $politician_id;
    # Ativando um chatbot para o político
    rest_put "/api/politician/$politician_id",
        name => 'activate chatbot',
        [
            fb_page_access_token => 'foo',
            fb_page_id           => 'bar'
        ]
    ;

    my $politician_entity_rs = $schema->resultset('PoliticianEntity');

    # Sincronizando intents com uma que deverá ser pulada
    db_transaction{
        setup_dialogflow_intents_response_with_skip();

        ok( $politician_entity_rs->sync_dialogflow, 'sync ok' );
        is( $politician_entity_rs->count, 2, '2 entities created' );
    };

    setup_dialogflow_intents_response();

    # Testando sync com get
    db_transaction{
		is( $politician_entity_rs->count, 0, 'no intents' );

        rest_get "/api/politician/$politician_id/intent",
            name    => 'invalid param',
            is_fail => 1,
            code    => 400,
            [ sync => 'foobar' ]
        ;

        rest_get "/api/politician/$politician_id/intent",
            name => 'get intent with sync',
            [ sync => 1 ]
        ;

		is( $politician_entity_rs->count, 3, '3 entities created' );

		rest_post "/api/politician/$politician_id/intent/sync",
		    name  => 'sync',
		    code  => 200,
		    stash => 'sync'
        ;
    };

    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 3, '3 entities created' );

    # Criando mais um chatbot e sincronizando
    # Para garantir que não há duplicação nas intents
    $politician    = create_politician;
    $politician_id = $politician->{id};
    $politician    = $schema->resultset('Politician')->find($politician_id);

	api_auth_as user_id => $politician_id;
    rest_put "/api/politician/$politician_id",
        name => 'activate chatbot',
        [
            fb_page_access_token => 'foo',
            fb_page_id           => 'baz'
        ]
    ;

    my $chatbot = $politician->user->organization->organization_chatbots->next;
    $chatbot->general_config->dialogflow_config->update( { project_id => 'foobar' } );

    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 6, '6 entities created' );

    # Sincronizando com uma intent deletada, ela deve ser deletada no banco também
	setup_dialogflow_intents_with_one_deleted_response();
    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 4,        '4 rows' );

    # Criando yet another chatbot
    # Porém dessa vez com um projeto do dialogflow diferente
    ok(
        my $dialogflow_config = $schema->resultset('DialogflowConfig')->create(
            {
                project_id  => 'second_project',
                credentials => '{}'
            }
        ),
        'dialogflow config'
    );

    $politician    = create_politician;
    $politician_id = $politician->{id};
    $politician    = $schema->resultset('Politician')->find($politician_id);

	api_auth_as user_id => $politician_id;
    rest_put "/api/politician/$politician_id",
        name => 'activate chatbot',
        [
            fb_page_access_token => 'fake_access_token',
            fb_page_id           => 'fake_page_id'
        ]
    ;

    $chatbot = $politician->user->organization->organization_chatbots->next;

    ok( $chatbot->general_config->update( { dialogflow_config_id => $dialogflow_config->id } ), 'update config id' );

	setup_dialogflow_intents_other_project_response();
	ok( $politician_entity_rs->sync_dialogflow,  'sync ok' );
	is( $politician_entity_rs->count, 6,         '6 rows' );
	is( $chatbot->politician_entities->count, 2, '2 rows' );
};

done_testing();