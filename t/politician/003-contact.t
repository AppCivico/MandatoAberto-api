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

    rest_get "/api/politician/$politician_id/contact",
        name  => "get politician contact",
        list  => 1,
        stash => "get_politician_contact"
    ;

    stash_test "get_politician_contact" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{id},        $contact_id, 'id');
        is ($res->{politician_contact}->{facebook},  'https://facebook.com/lucasansei', 'facebook');
        is ($res->{politician_contact}->{twitter},   '@lucas_ansei', 'twitter');
        is ($res->{politician_contact}->{email},     'foobar@email.com', 'email');
        is ($res->{politician_contact}->{cellphone}, undef, 'cellphone');
    };

    rest_put "/api/politician/$politician_id/contact/$contact_id",
        name    => "PUT invalid twitter",
        is_fail => "1",
        code    => 400,
        [
            twitter => 'this is a twitter account'
        ]
    ;

    rest_put "/api/politician/$politician_id/contact/$contact_id",
        name    => "PUT invalid email",
        is_fail => "1",
        code    => 400,
        [
            email => 'this is an email address'
        ]
    ;

    rest_put "/api/politician/$politician_id/contact/$contact_id",
        name    => "PUT invalid cellphone",
        is_fail => "1",
        code    => 400,
        [
            cellphone => 'this is a cellphone number'
        ]
    ;

    rest_put "/api/politician/$politician_id/contact/$contact_id",
        name    => "PUT invalid facebook",
        is_fail => "1",
        code    => 400,
        [
            facebook => 'this is a facebook URI'
        ]
    ;

    my $facebook  = 'https://www.facebook.com/pagina';
    my $cellphone = fake_digits("+551198#######")->();
    my $email     = fake_email()->();
    my $twitter   = '@twitter_pol';

    rest_put "/api/politician/$politician_id/contact/$contact_id",
        name    => "PUT sucessfuly",
        [
            facebook  => $facebook,
            cellphone => $cellphone,
            email     => $email,
            twitter   => $twitter
        ]
    ;

    rest_reload_list "get_politician_contact";

    stash_test "get_politician_contact.list" => sub {
        my $res = shift;

        is ($res->{politician_contact}->{id},        $contact_id, 'id');
        is ($res->{politician_contact}->{facebook},  $facebook, 'facebook');
        is ($res->{politician_contact}->{twitter},   $twitter, 'twitter');
        is ($res->{politician_contact}->{email},     $email, 'email');
        is ($res->{politician_contact}->{cellphone}, $cellphone, 'cellphone');
    };
};

done_testing();