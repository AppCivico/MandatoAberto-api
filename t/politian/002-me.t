use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $party  = fake_int(1, 35)->();
    my $office = fake_int(1, 8)->();

    create_politian(
        name                => "Lucas Ansei",
        address_state       => 'SP',
        address_city        => 'São Paulo',
        party_id            => $party,
        office_id           => $office,
        fb_page_id          => "FOO",
        fb_app_id           => "BAR",
        fb_app_secret       => "foobar",
        fb_page_acess_token => "FOOBAR"
    );

    my $politian_id = stash "politian.id";

    rest_get "/api/politian/$politian_id",
        name    => "get when logged off --fail",
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politian_id;
    rest_get "/api/politian/$politian_id",
        name  => "get politian",
        list  => 1,
        stash => "get_politian"
    ;

    stash_test "get_politian" => sub {
        my $res = shift;

        is ($res->{id}, $politian_id,  'id');
        is ($res->{name}, "Lucas Ansei", 'name');
        is ($res->{address_state}, "SP" , 'address_state');
        is ($res->{address_city}, "São Paulo" , 'address_city');
        is ($res->{party_id}, $party , 'party');
        is ($res->{office_id}, $office , 'office');
        is ($res->{fb_page_id}, "FOO" , 'fb_page_id');
        is ($res->{fb_app_id}, "BAR" , 'fb_app_id');
        is ($res->{fb_app_secret}, "foobar" , 'fb_app_secret');
        is ($res->{fb_page_acess_token}, "FOOBAR" , 'fb_page_acess_token');
    };

    rest_put "/api/politian/$politian_id",
        name => "update politian",
        [
            name         => "Ansei Lucas",
            address_city => "Ubatuba"
        ]
    ;

    rest_reload_list "get_politian";

    stash_test "get_politian.list" => sub {
        my $res = shift;

        is($res->{name},      "Ansei Lucas", "name updated");
        is($res->{address_city}, "Ubatuba",   "city updated");
    };

    create_politian;
    rest_get [ "api", "politian", stash "politian.id" ], name => "can't get other politian", is_fail => 1, code => 403;
    rest_put [ "api", "politian", stash "politian.id" ],
        name    => "can't put other politian",
        is_fail => 1,
        code    => 403,
        [ name => fake_name()->() ]
    ;
};

done_testing();