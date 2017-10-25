use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email = fake_email()->();

    rest_post "/api/register/politian",
        name                => "Sucessful politian creation",
        stash               => "d1",
        automatic_load_item => 0,
        [
            email         => $email,
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    is (
        $schema->resultset("Politian")->find(stash "d1.id")->user->email,
        $email,
        "created user and donor",
    );

    rest_post "/api/register/politian",
        name    => "Politian without email",
        is_fail => 1,
        [
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian without name",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian without address data",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian with invalid address_state",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'ZL',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian with invalid address_city",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'Rapture',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian without party",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politian",
        name    => "Politian without office",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
        ]
    ;

    # Partido e cargo devem ser integers
    rest_post "/api/register/politian",
        name    => "Politian with invalid party",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => 'AppCivico',
            office_id     => fake_int(1, 8)->(),
        ]
    ;

    # Partido e cargo devem ser integers
    rest_post "/api/register/politian",
        name    => "Politian with invalid party",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            address_state => 'SP',
            address_city  => 'São Paulo',
            party_id      => fake_int(1, 35)->(),
            office_id     => 'Developer',
        ]
    ;
};

done_testing();