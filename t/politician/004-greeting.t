use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;

db_transaction {
    my $politician = create_politician;
    my $politician_id = $politician->{id};

    subtest 'Greeting | wrong perms' => sub {
        api_auth_as user_id => 1;

        $t->post_ok("/api/politician/$politician_id/greeting")
        ->status_is(403);
    };

    subtest 'Greeting | get and create' => sub {

        api_auth_as user_id => $politician_id;

        $t->post_ok("/api/politician/$politician_id/greeting")
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/greeting",
            form => { on_website => 'foobar' }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/greeting",
            form => { on_facebook => 'foobar' }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/greeting",
            form => {
                on_facebook => 'foobar',
                on_website  => 'foobar2',
            }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/greeting")
        ->status_is(200)
        ->json_is('/on_facebook', 'foobar',  'greeting on facebook')
        ->json_is('/on_website',  'foobar2', 'greeting on website');
    };
};

done_testing();
