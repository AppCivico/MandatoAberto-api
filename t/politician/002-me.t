use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $party  = fake_int(1, 35)->();
    my $office = fake_int(1, 8)->();
    my $gender = fake_pick(qw/F M/)->();

    create_politician(
        name                => "Lucas Ansei",
        address_state       => 'SP',
        address_city        => 'São Paulo',
        party_id            => $party,
        office_id           => $office,
        fb_page_id          => "FOO",
        fb_app_id           => "BAR",
        fb_app_secret       => "foobar",
        fb_page_acess_token => "FOOBAR",
        gender              => $gender,
    );

    my $politician_id = stash "politician.id";

    rest_get "/api/politician/$politician_id",
        name    => "get when logged off --fail",
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;


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
    my $contact_id = stash "c1.id";

    rest_post "/api/politician/$politician_id/biography",
        name                => "biography sucessful creation",
        automatic_load_item => 0,
        stash               => 'b1',
        [ content => "foobar" ]
    ;
    my $biography_id = stash "b1.id";

    rest_get "/api/politician/$politician_id",
        name  => "get politician",
        list  => 1,
        stash => "get_politician"
    ;

    stash_test "get_politician" => sub {
        my $res = shift;

        is ($res->{id}, $politician_id,  'id');
        is ($res->{name}, "Lucas Ansei", 'name');
        is ($res->{address_state}, "SP" , 'address_state');
        is ($res->{address_city}, "São Paulo" , 'address_city');
        is ($res->{party}->{id}, $party , 'party');
        is ($res->{office}->{id}, $office , 'office');
        is ($res->{fb_page_id}, "FOO" , 'fb_page_id');
        is ($res->{fb_app_id}, "BAR" , 'fb_app_id');
        is ($res->{fb_app_secret}, "foobar" , 'fb_app_secret');
        is ($res->{fb_page_acess_token}, "FOOBAR" , 'fb_page_acess_token');
        is ($res->{gender}, $gender , 'gender');
        is ($res->{contact}->{id}, $contact_id , 'contact id');
        is ($res->{contact}->{twitter}, '@lucas_ansei', 'twitter');
        is ($res->{contact}->{facebook}, 'https://facebook.com/lucasansei', 'facebook');
        is ($res->{contact}->{email}, 'foobar@email.com', 'email');
        is ($res->{biography}->{id}, $biography_id, 'biography_id');
        is ($res->{biography}->{content}, 'foobar', 'biography content');
    };

    rest_put "/api/politician/$politician_id",
        name => "update politician",
        [
            name         => "Ansei Lucas",
            address_city => "Ubatuba"
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is($res->{name},      "Ansei Lucas", "name updated");
        is($res->{address_city}, "Ubatuba",   "city updated");
    };

    create_politician;
    rest_get [ "api", "politician", stash "politician.id" ], name => "can't get other politician", is_fail => 1, code => 403;
    rest_put [ "api", "politician", stash "politician.id" ],
        name    => "can't put other politician",
        is_fail => 1,
        code    => 403,
        [ name => fake_name()->() ]
    ;
};

done_testing();