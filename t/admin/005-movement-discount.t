use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    api_auth_as user_id => 1;

    rest_post '/api/admin/movement',
        name                => 'create movement',
        automatic_load_item => 0,
        stash               => 'm1',
        [ name => 'AppCívico' ]
    ;
    my $movement_id = stash 'm1.id';

    rest_post '/api/admin/movement',
        name                => 'create movement',
        automatic_load_item => 0,
        stash               => 'm2',
        [ name => 'Eokoe' ]
    ;
    my $second_movement_id = stash 'm2.id';

    ok ( my $movement        = $schema->resultset('Movement')->find( $movement_id ),        'movement created' );
    ok ( my $second_movement = $schema->resultset('Movement')->find( $second_movement_id ), 'movement created' );


    rest_post "/api/admin/movement/$movement_id/discount",
        name    => 'discount without movement_id',
        is_fail => 1,
        code    => 400,
        [ amount => 1000 ]
    ;

    rest_post "/api/admin/movement/$movement_id/discount",
        name    => 'discount without amount or percentage',
        is_fail => 1,
        code    => 400,
        [ movement_id => $movement_id ]
    ;

    rest_post "/api/admin/movement/$movement_id/discount",
        name    => 'discount with both amount and percentage',
        is_fail => 1,
        code    => 400,
        [
            movement_id => $movement_id,
            amount      => 1000,
            percentage  => '10.00'
        ]
    ;

    $ENV{MANDATOABERTO_BASE_AMOUNT} = 10000;

    rest_post "/api/admin/movement/$movement_id/discount",
        name => 'create discount with amount',
        automatic_load_item => 0,
        stash               => 'd1',
        [
            movement_id => $movement_id,
            amount      => 1000
        ]
    ;

    is ( $movement->calculate_discount, '90', 'expected final amount' );

    rest_post "/api/admin/movement/$second_movement_id/discount",
        name => 'create discount with percentage',
        automatic_load_item => 0,
        stash               => 'd2',
        [
            movement_id => $second_movement_id,
            percentage  => '20.00'
        ]
    ;

    is ( $second_movement->calculate_discount, '80', 'expected final amount' );

};

done_testing();