use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    is ($schema->resultset('EmailQueue')->count, "1", "only greetings email queued");

    my $politician_user = $schema->resultset("User")->find($politician_id);

    api_auth_as user_id => $politician_id;

    rest_post "/api/admin/politician/approve",
        name    => "approving as politician",
        is_fail => 1,
        code    => 403,
        [
            politician_id => $politician_id,
            approved      => 1
        ]
    ;

    api_auth_as user_id => 1;

    rest_post "/api/admin/politician/approve",
        name    => 'approving politician without politician_id',
        is_fail => 1,
        code    => 400,
        [ approved => 1 ]
    ;

    rest_post "/api/admin/politician/approve",
        name    => 'approving politician without approved bool',
        is_fail => 1,
        code    => 400,
        [ politician_id => $politician_id ]
    ;

    rest_post "/api/admin/politician/approve",
        name    => 'approving politician with invalid politician_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id => 99999,
            approved      => 1
        ]
    ;

    rest_post "/api/admin/politician/approve",
        name => 'approving politician',
        code => 200,
        [
            politician_id => $politician_id,
            approved      => 1
        ]
    ;

    $politician_user = $politician_user->discard_changes;

    is (
        $politician_user->approved,
        1,
        "politician is approved"
    );

    is ($schema->resultset('EmailQueue')->count, "2", "only greetings email queued");

    rest_post "/api/admin/politician/approve",
        name    => 'approving politician once again',
        is_fail => 1,
        code    => 400,
        [
            politician_id => $politician_id,
            approved      => 1
        ]
    ;

    rest_post "/api/admin/politician/approve",
        name => 'disapproving politician',
        code => 200,
        [
            politician_id => $politician_id,
            approved      => 0
        ]
    ;

    $politician_user = $politician_user->discard_changes;

    is (
        $politician_user->approved,
        0,
        "politician is not approved"
    );
};

done_testing();