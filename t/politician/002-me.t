use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

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
        gender               => $gender,
        movement_id          => $movement_id
    );

    my $politician_id   = stash "politician.id";
    my $politician      = $schema->resultset("Politician")->find($politician_id);
    my $politician_user = $schema->resultset("User")->find($politician_id);

    rest_get "/api/politician/$politician_id",
        name    => "get when logged off --fail",
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    $politician_user->update( { approved => 1 } );

    is($schema->resultset('PoliticianPrivateReplyConfig')->count, 1, 'one private_reply config created');
    is($schema->resultset('PollSelfPropagationConfig')->count,    1, 'one poll_self_propagation config created');

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
        [
            on_facebook => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
            on_website  => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
        ]
    ;
    my $greeting    = stash "g1";
    my $greeting_id = $greeting->{id};

    rest_get "/api/politician/$politician_id",
        name  => "get politician",
        list  => 1,
        stash => "get_politician"
    ;

    my $movement = $schema->resultset("Movement")->find($movement_id);

    stash_test "get_politician" => sub {
        my $res = shift;

        is ($res->{id},                      $politician_id,                    'id');
        is ($res->{name},                    "Lucas Ansei",                     'name');
        is ($res->{state}->{code},           "SP",                              'state code');
        is ($res->{state}->{name},           "São Paulo",                       'state name');
        is ($res->{city}->{name},            "São Paulo",                       'city');
        is ($res->{party}->{id},             $party,                            'party');
        is ($res->{office}->{id},            $office,                           'office');
        is ($res->{fb_page_id},              "fake_page_id",                    'fb_page_id');
        is ($res->{gender},                  $gender,                           'gender');
        is ($res->{premium},                 0,                                 'politician is not premium');
        is ($res->{contact}->{id},           $contact_id,                       'contact id');
        is ($res->{contact}->{twitter},      '@lucas_ansei',                    'twitter');
        is ($res->{contact}->{facebook},     'https://facebook.com/lucasansei', 'facebook');
        is ($res->{contact}->{email},        'foobar@email.com',                'email');
        is ($res->{contact}->{url},          "https://www.google.com",          'url');
        is ($res->{greeting}->{id},          $greeting_id,                      'greeting entity id');
        is ($res->{movement}->{id},          $movement->id,                     'movement id');
        is ($res->{movement}->{name},        $movement->name,                   'movement name');

        is (
            $res->{greeting}->{on_facebook},
            'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
            'greeting content'
        );
    };

    # Testando role para módulo de perfil
    db_transaction{
        db_transaction{
            $schema->resultset('UserRole')->search(
                {
                    user_id => $politician_id,
                    role_id => { -in => [ 11, 12 ] }
                }
            )->delete;

            rest_put "/api/politician/$politician_id",
                name    => "updating profile without roles",
                is_fail => 1,
                code    => 403,
                [ name => 'foobar' ]
            ;
        };

		rest_put "/api/politician/$politician_id",
            name => "updating name",
            [ name => 'foobar' ]
        ;
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

    rest_put "/api/politician/$politician_id",
        name => "Removing party and office",
        [
            office_id => 0,
            party_id  => 0
        ]
    ;

    rest_reload_list "get_politician";

    stash_test "get_politician.list" => sub {
        my $res = shift;

        # is ($res->{party}->id, '707977922439733248', 'twitter id');
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
