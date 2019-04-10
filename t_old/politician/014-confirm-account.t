use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model('DB');

db_transaction {
    # Criando um user.
    rest_post "/api/register/politician",
        name                => "add user",
        stash               => "user",
        automatic_load_item => 0,
        params              => {
            email            => 'foobar@email.com',
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
            movement_id      => fake_int(1, 7)->()
        },
    ;

    ok (my $user = $schema->resultset("User")->find(stash "user.id"), 'get user');
    is ($user->confirmed, 0, "user not confirmed");

    # Usando um token falso.
    # A fim de evitar ataques de brute force, eu não sinalizo quando o token é inválido. Isto implica que o
    # endpoint retornará 200 com qualquer string.
    rest_post "/api/login/confirm",
        name  => "confirm with fake token",
        code  => 200,
        params => {
            token => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        },
    ;
    is ($user->discard_changes->confirmed, 0, "user not confirmed");

    # Agora eu envio o token correto.
    ok (
        my $user_confirmation = $schema->resultset("UserConfirmation")->search({ user_id => stash "user.id" })->next,
        'get confirmation token',
    );

    rest_post "/api/login/confirm",
        name  => "confirm account",
        code  => 200,
        params => {
            token => $user_confirmation->token,
        },
    ;

    is ($user->discard_changes->confirmed, 1, "user confirmed");

};

done_testing();

