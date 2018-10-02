use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $email    = fake_email()->();
    my $password = "foobarquux1";

    create_politician(
        email    => $email,
        password => $password,
    );

    ok my $politician_id = $t->tx->res->json->{id};

    subtest 'Admin | approve politician' => sub {

        api_auth_as user_id => $politician_id;
        $t->post_ok(
            '/api/admin/politician/approve',
            form => {
                approved      => 1,
                politician_id => $politician_id,
            }
        )
        ->status_is(403)
        ->json_has('/error');

        api_auth_as user_id => 1;
        $t->post_ok(
            '/api/admin/politician/approve',
            form => {
                approved      => 1,
                politician_id => $politician_id,
            }
        )
        ->status_is(200);

        is( $schema->resultset('EmailQueue')->count, '3', 'all emails queued' );
    };

    subtest 'Politician | right login' => sub {

        api_auth_as 'nobody';

        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => $password,
            }
        )
        ->status_is(200)
        ->json_has('/api_key')
        ->json_is('/roles' => ['politician'])
        ->json_is('/user_id' => $politician_id);

        ok(
            $schema->resultset('UserSession')->search(
                {
                    'user.id'        => $politician_id,
                    'me.valid_until' => { '>=' => \'NOW()' }
                },
                { join => "user" },
            )->next,
            'created user session',
        );
    };

    subtest 'Politician | wrong login' => sub {

        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => "ALL YOUR BASE ARE BELONG TO US",
            }
        )
        ->status_is(400);
    };

    subtest 'Politician | not existent' => sub {

        $t->post_ok(
            '/api/login',
            form => {
                email    => 'fooobar@email.com',
                password => $password,
            }
        )
        ->status_is(400);
    };

};

done_testing();
