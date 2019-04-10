use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email    = fake_email()->();
    my $password = "foobarquux1";

    create_politician(
        email    => $email,
        password => $password
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/login",
        name    => "wrong login",
        is_fail => 1,
        [
            email    => $email,
            password => "ALL YOUR BASE ARE BELONG TO US",
        ],
    ;

    rest_post "/api/login",
        name    => "user not existent",
        is_fail => 1,
        code    => 400,
        [
            email    => 'fooobar@email.com',
            password => $password,
        ],
    ;

    api_auth_as user_id => 1;

    is ($schema->resultset('EmailQueue')->count, "2", "only greetings and new register emails queued");

    rest_post "/api/admin/politician/approve",
        name => "approving politician",
        code => 200,
        [
            approved      => 1,
            politician_id => $politician_id
        ]
    ;

    is ($schema->resultset('EmailQueue')->count, "3", "all emails queued");


    rest_post "/api/login",
        name  => "login",
        code  => 200,
        stash => "l1",
        [
            email    => $email,
            password => $password,
        ],
    ;

    ok (
        my $user_session = $schema->resultset("UserSession")->search(
            {
                "user.id"   => stash "politician.id",
                # valid_until => { ">=" => \"NOW()" }
            },
            { join => "user" },
        )->next,
        "created user session",
    );

    # A resposta foi a esperada?
    stash_test 'l1' => sub {
        my $res = shift;

        is( $res->{api_key},    $user_session->api_key,  'api_key ok' );
        is( $res->{user_id},    $user_session->user->id, 'user_id ok' );
        is( $res->{roles}->[0], 'politician', 'first role ok' );
    }
};

done_testing();
