use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    api_auth_as user_id => 1;

    rest_post '/api/admin/movement',
        name    => 'create movement without name',
        is_fail => 1,
        code    => 400
    ;

    rest_post '/api/admin/movement',
        name                => 'create movement',
        automatic_load_item => 0,
        stash               => 'm1',
        [ name => 'AppCívico' ]
    ;
    my $movement_id = stash 'm1.id';

    ok ( $schema->resultset('Movement')->count > 0,                           'at least one movement on db'  );
    ok ( my $movement = $schema->resultset('Movement')->find( $movement_id ), 'movement created' );

};

done_testing();