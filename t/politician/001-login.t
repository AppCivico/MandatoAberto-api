use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = get_schema;

db_transaction {
    my $email    = fake_email()->();
    my $password = "foobarquux1";

    create_politician(
        email    => $email,
        password => $password
    );

    ok my $politician_id = $t->tx->res->json->{id};
};

done_testing();

__END__



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

    $schema->resultset("User")->find($politician_id)->update({ approved => 1 });

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
    is_deeply(
        stash "l1",
        {
            api_key => $user_session->api_key,
            roles   => ["politician"],
            user_id => $user_session->user->id,
        },
    );
};

done_testing();