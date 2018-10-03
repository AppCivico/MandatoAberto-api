use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $party       = fake_int(1, 35)->();
    my $office      = fake_int(1, 8)->();
    my $gender      = fake_pick(qw/F M/)->();
    my $email       = fake_email()->();
    my $password    = "foobar";
    my $movement_id = fake_int(1, 6)->();

    create_politician(
        email                => $email,
        password             => $password,
        name                 => "Lucas Ansei",
        address_state        => 26,
        address_city_id      => 9508,
        party_id             => $party,
        office_id            => $office,
        fb_page_id           => "FOO",
        fb_page_access_token => "FOOBAR",
        gender               => $gender,
        movement_id          => $movement_id
    );

    ok my $politician_id = $t->tx->res->json->{id};

    ok $schema->resultset('User')->find($politician_id)->update( { approved => 1 } );

    $t->get_ok("/api/politician/$politician_id")
    ->status_is(403)
    ->json_has('/error');

    my $contact_id;
    subtest 'Politician | contact' => sub {

        api_auth_as user_id => $politician_id;

        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                twitter  => '@lucas_ansei',
                facebook => 'https://facebook.com/lucasansei',
                email    => 'foobar@email.com',
                url      => "https://www.google.com",
            }
        )
        ->status_is(200)
        ->json_has('/id')
        ->json_is('/cellphone' => undef)
        ->json_is('/instagram' => undef)
        ->json_is('/twitter'   => '@lucas_ansei')
        ->json_is('/facebook'  => 'https://facebook.com/lucasansei');

        ok $contact_id = $t->tx->res->json->{id};
    };

    subtest 'Politician | greeting' => sub {

        $t->post_ok(
            "/api/politician/$politician_id/greeting",
            form => {
                on_facebook => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
                on_website  => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
            }
        )
        ->status_is(200);

        ok my $greeting    = $t->tx->res->json;
        ok my $greeting_id = $greeting->{id};

        ok my $movement = $schema->resultset('Movement')->search( { 'me.id' => $movement_id } )->next;

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/id',                $politician_id,                    'id')
        ->json_is('/name',              "Lucas Ansei",                     'name')
        ->json_is('/state/code',        "SP",                              'state code')
        ->json_is('/state/name',        "São Paulo",                       'state name')
        ->json_is('/city/name',         "São Paulo",                       'city')
        ->json_is('/party/id',          $party,                            'party')
        ->json_is('/office/id',         $office,                           'office')
        ->json_is('/fb_page_id',        "FOO",                             'fb_page_id')
        ->json_is('/gender',            $gender,                           'gender')
        ->json_is('/premium',           0,                                 'politician is not premium')
        ->json_is('/contact/id',        $contact_id,                       'contact id')
        ->json_is('/contact/twitter',   '@lucas_ansei',                    'twitter')
        ->json_is('/contact/facebook',  'https://facebook.com/lucasansei', 'facebook')
        ->json_is('/contact/email',     'foobar@email.com',                'email')
        ->json_is('/contact/url',       "https://www.google.com",          'url')
        ->json_is('/greeting/id',       $greeting_id,                      'greeting entity id')
        ->json_is('/movement/id',       $movement->id,                     'movement id')
        ->json_is('/movement/name',     $movement->name,                   'movement name')
        ->json_is(
            '/greeting/on_facebook',
            'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
        );

        # Caso apenas a cidade seja editada, deve bater com o estado corrente
        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                address_city_id => 400,
            },
        )
        ->status_is(400)
        ->json_is('/form_error/address_city_id', 'city does not belong to state id: 26');

        # Caso o estado seja editado, deve ser editada também a cidade
        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                address_state_id => 1,
            },
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                name            => "Ansei Lucas",
                address_city_id => 9552,
            },
        )
        ->status_is(202)
        ->header_like(Location => qr{/api/politician/[0-9]+$});
    };
};

done_testing();

__END__

    rest_put "/api/politician/$politician_id",
        name => "update politician",
        [

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

    rest_put "/api/politician/$politician_id",
        name => "Adding picframe URL and text",
        [
            picframe_url  => 'https://foobar.com.br',
            picframe_text => 'foobar'
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is($res->{picframe_url},  'https://foobar.com.br', 'picframe_url');
        is($res->{picframe_text}, 'foobar',                'share_text');
        is($res->{share_url},     'https://foobar.com.br', 'picframe_url');
        is($res->{share_text},    'foobar',                'share_text');
    };

    rest_put "/api/politician/$politician_id",
        name => "Adding picframe URL and text using share",
        [
            share_url  => 'https://google.com.br',
            share_text => 'barbaz'
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is($res->{picframe_url},  'https://google.com.br', 'picframe_url');
        is($res->{picframe_text}, 'barbaz',                'share_text');
        is($res->{share_url},     'https://google.com.br', 'picframe_url');
        is($res->{share_text},    'barbaz',                'share_text');
    };

    rest_put "/api/politician/$politician_id",
        name => "Removing share data",
        [
            share_url  => '',
            share_text => ''
        ]
    ;

	rest_reload_list "get_politician";

	stash_test "get_politician.list" => sub {
		my $res = shift;

		is($res->{picframe_url},  undef, 'picframe_url');
		is($res->{picframe_text}, undef,'share_text');
		is($res->{share_url},     undef, 'picframe_url');
		is($res->{share_text},    undef,                'share_text');
	};

    rest_put "/api/politician/$politician_id",
        name => "Adding picframe URL",
        [ deactivate_chatbot => 1 ]
    ;

    rest_put "/api/politician/$politician_id",
        name => "update political movement",
        [ movement_id => 7 ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is ($res->{movement}->{id}, 7, 'movement id');
    };

    rest_put "/api/politician/$politician_id",
        name    => "Adding twitter data without oauth",
        is_fail => 1,
        code    => 400,
        [
            twitter_id           => '707977922439733248',
            twitter_token_secret => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id",
        name    => "Adding twitter data without twitter_token_secret",
        is_fail => 1,
        code    => 400,
        [
            twitter_id           => '707977922439733248',
            twitter_oauth_token  => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id",
        name    => "Adding twitter data without twitter_id",
        is_fail => 1,
        code    => 400,
        [
            twitter_oauth_token  => 'foobar',
            twitter_token_secret => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id",
        name    => "Adding twitter data with invalid twitter_id",
        is_fail => 1,
        code    => 400,
        [
            twitter_id           => 'this is a text',
            twitter_oauth_token  => 'foobar',
            twitter_token_secret => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id",
        name    => "Adding twitter data",
        [
            twitter_id           => '707977922439733248',
            twitter_oauth_token  => 'foobar',
            twitter_token_secret => 'foobar'
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        is ($res->{twitter_id}, '707977922439733248', 'twitter id');
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