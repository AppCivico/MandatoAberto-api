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

    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 3, '3 entities created' );

    create_politician;
    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 6, '6 entities created' );
};

done_testing();