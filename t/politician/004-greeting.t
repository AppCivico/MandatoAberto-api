use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => 1;

    rest_post "/api/politician/$politician_id/greeting",
        name    => 'politician greeting as admin',
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/greeting",
        name    => 'politician greeting without greeting_id',
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name    => 'politician greeting without on_facebook',
        is_fail => 1,
        code    => 400,
        [ on_website => 'foobar' ]
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name    => 'politician greeting without on_website',
        is_fail => 1,
        code    => 400,
        [ on_facebook => 'foobar' ]
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name                => 'politician greeting',
        automatic_load_item => 1,
        stash               => 'g1',
        code                => 200,
        [
            on_facebook => 'foobar',
            on_website  => 'foobar2'
        ]
    ;

    rest_get "/api/politician/$politician_id/greeting",
        name  => "get politician greeting",
        list  => 1,
        stash => "get_politician_greeting"
    ;

    stash_test "get_politician_greeting" => sub {
        my $res = shift;

        is ($res->{on_facebook}, 'foobar',  'greeting on facebook');
        is ($res->{on_website},  'foobar2', 'greeting on website');
    };
};

done_testing();
