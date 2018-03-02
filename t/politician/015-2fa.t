use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician();
    my $politician_id = stash 'politician.id';
    api_auth_as user_id => $politician_id;

    # TODO Enable 2fa.
    subtest 'enable 2fa' => sub {

        rest_post "/api/politician/$politician_id/two-factor-authentication/enable",
            name  => 'enable 2fa',
            stash => 'enable',
            code  => 200,
        ;

        stash_test 'enable' => sub {
            my $res = shift;

            like( $res->{url}, qr/^https:\/\/www\.google\.com\/chart/, 'qr code' );
        };
    };

    subtest 'verify 2fa' => sub {

        rest_post "/api/politician/$politician_id/two-factor-authentication/verify",
            name  => 'verify 2fa',
            stash => 'verify',
            code  => 200,
            [ code => '123123' ],
        ;

        stash_test 'verify' => sub {
            my $res = shift;

            is( $res->{ok}, 0, 'ok=0' );
        };
    };
};

done_testing();
