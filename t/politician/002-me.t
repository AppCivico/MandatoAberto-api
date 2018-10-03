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

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/name',      "Ansei Lucas", "name updated")
        ->json_is('/city/name', "Ubatuba",     "city updated");
    };

    subtest 'Politician | change password' => sub {
        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => $password,
            }
        )
        ->status_is(200)
        ->json_has('/api_key');

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                new_password => "12345",
            },
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                new_password => "123456",
            },
        )
        ->status_is(202)
        ->header_like(Location => qr{/api/politician/[0-9]+$});

        # Login with old password.
        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => $password,
            }
        )
        ->status_is(400);

        # Login with right password.
        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => '123456',
            }
        )
        ->status_is(200)
        ->json_has('/api_key');
    };

    subtest 'Politician | social share' => sub {

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                picframe_url  => 'https://foobar.com.br',
                picframe_text => 'foobar',
            }
        )
        ->status_is(202)
        ->json_has('/id');

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/picframe_url',  'https://foobar.com.br', 'picframe_url')
        ->json_is('/picframe_text', 'foobar',                'share_text')
        ->json_is('/share_url',     'https://foobar.com.br', 'picframe_url')
        ->json_is('/share_text',    'foobar',                'share_text');

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                share_url  => 'https://google.com.br',
                share_text => 'barbaz',
            }
        )
        ->status_is(202)
        ->json_has('/id');

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/picframe_url',  'https://google.com.br', 'picframe_url')
        ->json_is('/picframe_text', 'barbaz',                'share_text')
        ->json_is('/share_url',     'https://google.com.br', 'picframe_url')
        ->json_is('/share_text',    'barbaz',                'share_text');

        # Remove data.
        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                share_url  => '',
                share_text => '',
            }
        )
        ->status_is(202)
        ->json_has('/id');

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/picframe_url',  undef, 'picframe_url')
        ->json_is('/picframe_text', undef,'share_text')
        ->json_is('/share_url',     undef, 'picframe_url')
        ->json_is('/share_text',    undef, 'share_text');

        $t->put_ok(
            "/api/politician/$politician_id",
            form => { deactivate_chatbot => 1 }
        )
        ->status_is(202);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => { movement_id => 7 }
        )
        ->status_is(202);

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/movement/id', 7, 'movement_id=7');

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                twitter_id           => '707977922439733248',
                twitter_token_secret => 'foobar'
            }
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                twitter_id           => '707977922439733248',
                twitter_oauth_token  => 'foobar'
            }
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                twitter_oauth_token  => 'foobar',
                twitter_token_secret => 'foobar'
            }
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                twitter_id           => 'this is a text',
                twitter_oauth_token  => 'foobar',
                twitter_token_secret => 'foobar'
            }
        )
        ->status_is(400);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                twitter_id           => '707977922439733248',
                twitter_oauth_token  => 'foobar',
                twitter_token_secret => 'foobar'
            }
        );

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(200)
        ->json_is('/twitter_id', '707977922439733248', 'twitter_id');
    };

    subtest 'Politician | only get me' => sub {

        create_politician;
        my $politician_id = $t->tx->res->json->{id};

        $t->get_ok("/api/politician/$politician_id")
        ->status_is(403);

        $t->put_ok(
            "/api/politician/$politician_id",
            form => { name => fake_name()->() }
        )
        ->status_is(403);
    };
};

done_testing();
