use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email = fake_email()->();

    setup_dialogflow_intents_response();
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
            movement_id      => fake_int(1, 7)->()
        ]
    ;

    # is($schema->resultset('PoliticianEntity')->count, "3", "3 entities created");
    is($schema->resultset('EmailQueue')->count, "2", "greetings and new register emails");

    is (
        $schema->resultset("User")->find(stash "d1.id")->email,
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