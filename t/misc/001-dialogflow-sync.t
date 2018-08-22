use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $entity_rs = $schema->resultset('Entity');
    my $politician_entity_rs = $schema->resultset('PoliticianEntity');

    setup_dialogflow_entities_response();

    # Pre-criando uma entidade que estará na resposta
    db_transaction{
        $entity_rs->create( { name => 'Aborto' } );

    	is ( $entity_rs->count, 1, '1 entity alredy created' );
        ok ( $entity_rs->sync_with_dialogflow, 'sync ok' );
    	is ( $entity_rs->count, 3, '3 entities on db' );
    };

    # Pre-criando uma entidade que não estará na resposta
    db_transaction{
        $entity_rs->create( { name => 'Feminismo' } );

    	is ( $entity_rs->count, 1, '1 entity alredy created' );
        ok ( $entity_rs->sync_with_dialogflow, 'sync ok' );
    	is ( $entity_rs->count, 4, '4 entities on db' );
    };

    ok ( $entity_rs->sync_with_dialogflow, 'sync ok' );
    is ( $entity_rs->count, 3, '3 entities created' );


};

done_testing();