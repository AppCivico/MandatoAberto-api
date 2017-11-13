use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => 1;
    rest_post "/api/politician/$politician_id/contact",
        name    => "politician contact as admin",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/contact",
        name    => "politician without any contact",
        is_fail => 1,
        code    => 400
    ;

    rest_post "/api/politician/$politician_id/contact",
        name                => "politician contact",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            twitter  => '@lucas_ansei',
            facebook => 'https://facebook.com/lucasansei',
            email    => 'foobar@email.com'
        ]
    ;

    rest_get "/api/politician/$politician_id/contact",
        name  => "get politician contact",
        list  => 1,
        stash => "get_politician_contact"
    ;

    stash_test "get_politician_contact" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{facebook},  'https://facebook.com/lucasansei', 'facebook');
        is ($res->{politician_contact}->{twitter},   '@lucas_ansei', 'twitter');
        is ($res->{politician_contact}->{email},     'foobar@email.com', 'email');
        is ($res->{politician_contact}->{cellphone}, undef, 'cellphone');
    }
};

done_testing();