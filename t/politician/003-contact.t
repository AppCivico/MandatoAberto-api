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

    # Facebook must be an URI
    rest_post "/api/politician/$politician_id/contact",
        name    => "politician with invalid Facebook",
        is_fail => 1,
        code    => 400,
        [
            facebook => 'Foobar',
        ]
    ;

    rest_post "/api/politician/$politician_id/contact",
        name    => "politician with invalid email",
        is_fail => 1,
        code    => 400,
        [
            email => 'Foobar',
        ]
    ;

    rest_post "/api/politician/$politician_id/contact",
        name    => "politician with invalid cellphone",
        is_fail => 1,
        code    => 400,
        [
            cellphone => 'Foobar',
        ]
    ;

    rest_post "/api/politician/$politician_id/contact",
        name    => "politician with invalid url",
        is_fail => 1,
        code    => 400,
        [
            url => 1,
        ]
    ;

    rest_post "/api/politician/$politician_id/contact",
        name    => "politician with invalid url",
        is_fail => 1,
        code    => 400,
        [
            url => 'foobar',
        ]
    ;

    my $twitter  = '@lucas_ansei';
    my $facebook = 'https://facebook.com/lucasansei';

    rest_post "/api/politician/$politician_id/contact",
        name                => "politician contact",
        automatic_load_item => 0,
        code                => 200,
        stash               => 'c1',
        [
            twitter  => '@lucas_ansei',
            facebook => 'https://facebook.com/lucasansei',
            email    => 'foobar@email.com',
            url      => 'https://www.google.com'
        ]
    ;
    my $contact = stash "c1";

    rest_get "/api/politician/$politician_id/contact",
        name  => "get politician contact",
        list  => 1,
        stash => "get_politician_contact"
    ;

    stash_test "get_politician_contact" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{id},        $contact->{id}, 'id');
        is ($res->{politician_contact}->{facebook},  'https://facebook.com/lucasansei', 'facebook');
        is ($res->{politician_contact}->{twitter},   '@lucas_ansei', 'twitter');
        is ($res->{politician_contact}->{email},     'foobar@email.com', 'email');
        is ($res->{politician_contact}->{url},       'https://www.google.com', 'url');
        is ($res->{politician_contact}->{cellphone}, undef, 'cellphone');
    };

    rest_post "/api/politician/$politician_id/contact",
        name                => "update politician contact",
        automatic_load_item => 0,
        code                => 200,
        stash               => 'c2',
        [
            twitter  => '@foobar',
            facebook => 'https://facebook.com/aaaa',
            email    => 'foobar@aaaaa.com',

        ]
    ;

    rest_reload_list "get_politician_contact";
    stash_test "get_politician_contact.list" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{id},        $contact->{id}, 'id');
        is ($res->{politician_contact}->{facebook},  'https://facebook.com/aaaa', 'facebook');
        is ($res->{politician_contact}->{twitter},   '@foobar', 'twitter');
        is ($res->{politician_contact}->{email},     'foobar@aaaaa.com', 'email');
        is ($res->{politician_contact}->{cellphone}, undef, 'cellphone');
    };

    rest_post "/api/politician/$politician_id/contact",
        name  => 'removing contacts',
        stash => 'c3',
        code  => 200,
    ;

    rest_reload_list "get_politician_contact";
    stash_test "get_politician_contact.list" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{id},        $contact->{id}, 'id');
        is ($res->{politician_contact}->{facebook},  undef, 'facebook');
        is ($res->{politician_contact}->{twitter},   undef, 'twitter');
        is ($res->{politician_contact}->{email},     undef, 'email');
        is ($res->{politician_contact}->{cellphone}, undef, 'cellphone');
    };
};

done_testing();