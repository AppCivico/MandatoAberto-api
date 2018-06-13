use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email = fake_email()->();

    rest_post "/api/register/politician",
        name                => "Sucessful politician creation",
        stash               => "d1",
        automatic_load_item => 0,
        [
            email            => $email,
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

	is($schema->resultset('EmailQueue')->count, "2", "greetings and new register emails");
	is($schema->resultset('PoliticianPrivateReplyConfig')->count, "1", "one config created");

    is (
        $schema->resultset("Politician")->find(stash "d1.id")->user->email,
        $email,
        "created user and politician",
    );

    rest_post "/api/register/politician",
        name    => "politician without email",
        is_fail => 1,
        [
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician without name",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician without address data",
        is_fail => 1,
        [
            email         => fake_email()->(),
            password      => '1234567',
            name          => 'Lucas Ansei',
            party_id      => fake_int(1, 35)->(),
            office_id     => fake_int(1, 8)->(),
            gender        => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician with invalid address_state_id",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 'ZL',
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician with invalid address_city_id",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 'Rapture',
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician with invalid address_city_id that does not belogs to state",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 400,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician without party",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician without office",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    # Partido e cargo devem ser integers
    rest_post "/api/register/politician",
        name    => "politician with invalid party",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => 'AppCivico',
            office_id        => fake_int(1, 8)->(),
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    # Partido e cargo devem ser integers
    rest_post "/api/register/politician",
        name    => "politician with invalid party",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => 'Developer',
            gender           => fake_pick(qw/F M/)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician without gender",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
        ]
    ;

    rest_post "/api/register/politician",
        name    => "politician with invalid gender",
        is_fail => 1,
        [
            email            => fake_email()->(),
            password         => '1234567',
            name             => 'Lucas Ansei',
            address_state_id => 26,
            address_city_id  => 9508,
            party_id         => fake_int(1, 35)->(),
            office_id        => fake_int(1, 8)->(),
            gender           => "A",
        ]
    ;
};

done_testing();