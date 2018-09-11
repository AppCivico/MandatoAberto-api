use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;

    my $politician_entity_rs = $schema->resultset('PoliticianEntity');

    setup_dialogflow_entities_response();

    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 3, '3 entities created' );

    create_politician;
    ok ( $politician_entity_rs->sync_dialogflow, 'sync ok' );
    is ( $politician_entity_rs->count, 6, '6 entities created' );
};

done_testing();