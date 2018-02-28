use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/premium",
        name    => "activating premium as politician",
        is_fail => 1,
        code    => 403,
        [ premium => 1 ]
    ;

    api_auth_as user_id => $politician_id;

    is (
        $schema->resultset("Politician")->find($politician_id)->premium,
        0,
        "politician isn't premium"
    );

    is ($schema->resultset('EmailQueue')->count, "1", "only greetings email queued");

    api_auth_as user_id => 1;

    rest_post "/api/politician/$politician_id/premium",
        name => "activating premium",
        code => 200,
        [ premium => 1 ]
    ;

    is (
        $schema->resultset("Politician")->find($politician_id)->premium,
        1,
        "politician is premium"
    );

    is ($schema->resultset('EmailQueue')->count, "2", "premium active email queued");

    rest_post "/api/politician/$politician_id/premium",
        name => "activating premium",
        code => 200,
        [ premium => 0 ]
    ;

    is (
        $schema->resultset("Politician")->find($politician_id)->premium,
        0,
        "politician is not premium"
    );

    is ($schema->resultset('EmailQueue')->count, "3", "premium inactive email queued");
};

done_testing();