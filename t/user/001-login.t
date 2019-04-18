use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {
    my $email    = 'lucas.ansei@appcivico.com';
    my $password = 'fake_password';

    my $organization_rs = $schema->resultset('Organization');

    my ($user, $user_id);
    subtest 'User | Register' => sub {
        $user = $t->post_ok(
            '/user',
            form => {
                name     => 'Lucas Ansei',
                password => $password,
                email    => $email,
            }
        )
        ->status_is(201);

        $user_id = $user->{id};
    };

    my $organization = $organization_rs->search(undef)->next;
    ok( $organization->update( { approved => 1 } ), 'approving organization' );

    subtest 'User | Login' => sub {
        $t->post_ok(
            '/login',
            form => {
                email    => $email,
                password => $password,
            }
        )
        ->status_is(200);
        my $res = $t->tx->res->json;

        ok (
            my $user_session = $schema->resultset("UserSession")->search(
                { "user.id"   => $user_id },
                { join => "user" },
            )->next,
            "created user session",
        );

        is( $res->{api_key}, $user_session->api_key,  'api_key ok' );
        is( $res->{user_id}, $user_session->user->id, 'user_id ok' );
    };
};

done_testing();
