use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $email    = fake_email()->();
    my $password = "foobarquux1";

    my $politician = create_politician(
		email    => $email,
		password => $password,
	);
    my $politician_id = $politician->{id};

    subtest 'Politician | forgot password' => sub {
        my $user = $schema->resultset("User")->find($politician_id);
        $user->update({ approved => 1 });

        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => $password
            }
        )
        ->status_is(200)
        ->json_is('/user_id', $user->id, 'user_id');

        for ( 1 .. 3 ) {
            $t->post_ok(
                '/api/login/forgot_password',
                form => { email => $user->email }
            )
            ->status_is(200);
        }

        is (
            $schema->resultset("UserForgotPassword")->search({
                user_id     => $user->id,
                valid_until => { '>=' => \'NOW()' },
            })->count,
            1,
            'only one token valid',
        );

        my $forgot_password = $schema->resultset('UserForgotPassword')->search({
            user_id     => $user->id,
            valid_until => { '>=' => \'NOW()' },
        })->next;

        my $token = $forgot_password->token;
        is (length $token, 40, 'token has 40 chars');

		my $new_password = random_string(8);

		$forgot_password->update( { valid_until => \"(NOW() - '1 minutes'::interval)" } );

        # reset password with invalid token returns ok
        $t->post_ok(
            "/api/login/forgot_password/reset/$token",
            form => { new_password => $new_password }
        )
        ->status_is(200);

		$forgot_password->update( { valid_until => \"(NOW() + '1 days'::interval)" } );

        # Nova senha não pode ser vazia ou menor que 4 digitos
        $t->post_ok(
            "/api/login/forgot_password/reset/$token",
            form => { new_password => "" }
        )
        ->status_is(400);

        # password with less than 4 chars must fail
        $t->post_ok(
            "/api/login/forgot_password/reset/$token",
            form => { new_password => "abc" }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/login/forgot_password/reset/$token",
            form => { new_password => $new_password }
        )
        ->status_is(200);

        ok (!defined($schema->resultset('UserForgotPassword')->search({ token => $token })->next), "token expired");

        $t->post_ok(
            '/api/login',
            form => {
                email    => $email,
                password => $new_password
            }
        )
        ->status_is(200);
    }
};

done_testing();