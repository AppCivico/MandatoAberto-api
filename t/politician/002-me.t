use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $party    = fake_int(1, 35)->();
    my $office   = fake_int(1, 8)->();
    my $gender   = fake_pick(qw/F M/)->();
    my $email    = fake_email()->();
    my $password = "foobar";

    create_politician(
        email               => $email,
        password            => $password,
        name                => "Lucas Ansei",
        address_state       => 26,
        address_city_id     => 9508,
        party_id            => $party,
        office_id           => $office,
        fb_page_id          => "FOO",
        fb_page_access_token => "FOOBAR",
        gender              => $gender,
    );

    my $politician_id = stash "politician.id";

    $schema->resultset("User")->find($politician_id)->update({ approved => 1 });

    rest_get "/api/politician/$politician_id",
        name    => "get when logged off --fail",
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;


    rest_post "/api/politician/$politician_id/contact",
        name                => "politician contact",
        automatic_load_item => 0,
        code                => 200,
        stash               => 'c1',
        [
            twitter  => '@lucas_ansei',
            facebook => 'https://facebook.com/lucasansei',
            email    => 'foobar@email.com',
            url      => "https://www.google.com",
        ]
    ;
    my $contact    = stash "c1";
    my $contact_id = $contact->{id};

    rest_post "/api/politician/$politician_id/greeting",
        name                => "politician greeting",
        code                => 200,
        automatic_load_item => 0,
        stash               => 'g1',
        [ greeting_id => 1 ]
    ;
    my $greeting    = stash "g1";
    my $greeting_id = $greeting->{id};

    rest_get "/api/politician/$politician_id",
        name  => "get politician",
        list  => 1,
        stash => "get_politician"
    ;

    stash_test "get_politician" => sub {
        my $res = shift;

        is ($res->{id}, $politician_id,  'id');
        is ($res->{name}, "Lucas Ansei", 'name');
        is ($res->{state}->{code}, "SP" , 'state code');
        is ($res->{state}->{name}, "São Paulo" , 'state name');
        is ($res->{city}->{name}, "São Paulo" , 'city');
        is ($res->{party}->{id}, $party , 'party');
        is ($res->{office}->{id}, $office , 'office');
        is ($res->{fb_page_id}, "FOO" , 'fb_page_id');
        is ($res->{gender}, $gender , 'gender');
        is ($res->{premium}, 0, 'politician is not premium');
        is ($res->{contact}->{id}, $contact_id , 'contact id');
        is ($res->{contact}->{twitter}, '@lucas_ansei', 'twitter');
        is ($res->{contact}->{facebook}, 'https://facebook.com/lucasansei', 'facebook');
        is ($res->{contact}->{email}, 'foobar@email.com', 'email');
        is ($res->{contact}->{url}, "https://www.google.com", 'url');
        is ($res->{greeting}->{id}, $greeting_id, 'greeting entity id');
        is ($res->{greeting}->{greeting_id}, 1, 'greeting id');
        is ($res->{greeting}->{content}, 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil a melhor e precisamos de sua ajuda.', 'greeting content');
        is ($res->{private_reply_activated}, 1, 'private reply active')
    };

    # Caso apenas a cidade seja editada, deve bater com o estado corrente
    rest_put "/api/politician/$politician_id",
        name    => "invalid address_city_id",
        is_fail => 1,
        code    => 400,
        [ address_city_id => 400 ]
    ;

    # Caso o estado seja editado, deve ser editada também a cidade
    rest_put "/api/politician/$politician_id",
        name    => "missing address_city_id",
        is_fail => 1,
        code    => 400,
        [ address_state_id => 1 ]
    ;

    rest_put "/api/politician/$politician_id",
        name => "update politician",
        [
            name            => "Ansei Lucas",
            address_city_id => 9552
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is($res->{name},         "Ansei Lucas", "name updated");
        is($res->{city}->{name}, "Ubatuba",   "city updated");
    };

    # Mudando a senha
    rest_post "/api/login",
        name  => "login with current password",
        code  => 200,
        [
            email    => $email,
            password => $password,
        ],
    ;

    rest_put "/api/politician/$politician_id",
        name    => "new password with less than 6 chars",
        is_fail => 1,
        code    => 400,
        [ new_password => "12345" ]
    ;

    rest_put "/api/politician/$politician_id",
        name    => "new password",
        [ new_password => "123456" ]
    ;

    rest_post "/api/login",
        name    => "login with old password",
        is_fail => 1,
        code    => 400,
        [
            email    => $email,
            password => $password,
        ],
    ;

    rest_post "/api/login",
        name => "login with new password",
        code => 200,
        [
            email    => $email,
            password => '123456',
        ],
    ;

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