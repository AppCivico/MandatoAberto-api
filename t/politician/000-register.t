use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = get_schema;

db_transaction {
    my $email = fake_email()->();

    subtest 'User | create' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email    => $email,
                password => '1234567',
                name     => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
                movement_id      => fake_int(1, 7)->(),
            }
        )
        ->status_is(201)
        ->json_has('/id');

        is( $schema->resultset('EmailQueue')->count, "2", "greetings and new register emails" );
        is( $schema->resultset('PoliticianPrivateReplyConfig')->count, "1", "one config created" );

        my $user_id = $t->tx->res->json->{id};
        is(
            $schema->resultset("Politician")->find($user_id)->user->email,
            $email,
            "created user and politician",
        );
    };

    subtest 'User | create without email' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create without name' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create without address data' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email         => fake_email()->(),
                password      => '1234567',
                name          => 'Lucas Ansei',
                party_id      => fake_int(1, 35)->(),
                office_id     => fake_int(1, 8)->(),
                gender        => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create with invalid address_state_id' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 'ZL',
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create with invalid address_city_id' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 'Rapture',
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 400,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create without party' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create without office' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create with invalid party' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => 'AppCivico',
                office_id        => fake_int(1, 8)->(),
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => 'Developer',
                gender           => fake_pick(qw/F M/)->(),
            }
        )
        ->status_is(400);
    };

    subtest 'User | create with invalid gender' => sub {

        $t->post_ok(
            '/api/register/politician',
            form => {
                email            => fake_email()->(),
                password         => '1234567',
                name             => 'Lucas Ansei',
                address_state_id => 26,
                address_city_id  => 9508,
                party_id         => fake_int(1, 35)->(),
                office_id        => fake_int(1, 8)->(),
                gender           => "A",
            }
        )
        ->status_is(400);
    };
};

done_testing();
