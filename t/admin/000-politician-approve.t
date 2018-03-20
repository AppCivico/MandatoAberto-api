use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    my $politician_user = $schema->resultset("User")->find($politician_id);

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/approve",
        name    => "approving as politician",
        is_fail => 1,
        code    => 403,
        [ approved => 1 ]
    ;

    is (
        $politician_user->approved,
        0,
        "politician isn't approved"
    );

    is ($schema->resultset('EmailQueue')->count, "1", "only greetings email queued");

    api_auth_as user_id => 1;

    rest_post "/api/politician/$politician_id/approve",
        name => "approving politician",
        code => 200,
        [ approved => 1 ]
    ;

    $politician_user = $politician_user->discard_changes;

    is (
        $politician_user->approved,
        1,
        "politician is approved"
    );

    is ($schema->resultset('EmailQueue')->count, "2", "approved email queued");

    rest_post "/api/politician/$politician_id/approve",
        name => "disapproving politician",
        code => 200,
        [ approved => 0 ]
    ;

    $politician_user = $politician_user->discard_changes;

    is (
        $politician_user->approved,
        0,
        "politician is approved"
    );
};

done_testing();