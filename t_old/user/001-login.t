use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email    = 'lucas.ansei@appcivico.com';
    my $password = 'fake_password';

    my $organization_rs = $schema->resultset('Organization');

    my ($user, $user_id);
    subtest 'User | Register' => sub {
        $user = rest_post '/api/register',
            is_fail             => 0,
            automatic_load_item => 0,
            code                => 201,
            [
                name     => 'Lucas Ansei',
                password => $password,
                email    => $email,
            ]
        ;

        $user_id = $user->{id};
    };

    my $organization = $organization_rs->search(undef)->next;
    ok( $organization->update( { approved => 1 } ), 'approving organization' );

    subtest 'User | Login' => sub {
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
                { "user.id"   => $user_id },
                { join => "user" },
            )->next,
            "created user session",
        );

        stash_test 'l1' => sub {
            my $res = shift;

            is( $res->{api_key},    $user_session->api_key,  'api_key ok' );
            is( $res->{user_id},    $user_session->user->id, 'user_id ok' );
        }
    };
};

done_testing();
