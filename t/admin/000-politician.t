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

    rest_get "/api/admin/politician",
        name    => 'get politicians as politician',
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => 1;

    rest_get "/api/admin/politician",
        name    => 'get politicians with pedencies',
        list  => 1,
        stash => "get_politicians_with_pedencies"
    ;

    stash_test "get_politicians_with_pedencies" => sub {
        my $res = shift;

        is ($res->{politicians}->[0]->{approved}, 0, 'approval pendency');
        is ($res->{politicians}->[0]->{premium}, 0, 'premium pendency');
    };

};

done_testing();