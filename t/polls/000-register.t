use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {

    subtest 'Admin | Create poll' => sub {
        api_auth_as user_id => 1;

        $t->post_ok(
            '/api/register/poll',
        )
        ->status_is(403);
    };

    my $politician = create_politician;
    my $poll_name  = fake_words(1)->();

    subtest 'Politician | Invalid polls' => sub {
        api_auth_as user_id => $politician->{id};

        # Poll without name
        $t->post_ok(
            '/api/register/poll',
            form => {
                status_id                  => 1,
                'questions[0]'             => 'alalala?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
            }
        )
        ->status_is(400);

        # Poll without status_id
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => 'foobar',
                'questions[0]'             => 'alalala?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
            }
        )
        ->status_is(400);

        # Poll with invalid question format
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 1,
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][0]' => 'Não',
            }
        )
        ->status_is(400);

        # Poll without options
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'Você está bem?',
            }
        )
        ->status_is(400);

        # Poll with question with only one option
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'foobar',
                'questions[0][options][0]' => 'Sim',
            }
        )
        ->status_is(400);

        # Poll with option with more than 20 characters
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'foobar',
                'questions[0][options][0]' => 'This is a string with more than 20 chars',
            }
        )
        ->status_is(400);

        # Creating one sucessful poll to test the repeated name restriction
        db_transaction{
			$t->post_ok(
				'/api/register/poll',
				form => {
					name                       => $poll_name,
					status_id                  => 1,
					'questions[0]'             => 'Você está bem?',
					'questions[0][options][0]' => 'Sim',
					'questions[0][options][1]' => 'Não',
					'questions[1]'             => 'foobar?',
					'questions[1][options][0]' => 'foo',
					'questions[1][options][1]' => 'bar',
					'questions[1][options][2]' => 'não',
				}
			)
            ->status_is(201);

            # Poll with repeated name
            $t->post_ok(
				'/api/register/poll',
				form => {
                    name                       => $poll_name,
                    status_id                  => 1,
                    'questions[0]'             => 'alalala?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
				}
			)
            ->status_is(400);
        };

        subtest 'Poll status' => sub {
            # Create deactivated poll
            $t->post_ok(
                '/api/register/poll',
                form => {
                    name                       => 'this is a deactivated poll',
                    status_id                  => 3,
                    'questions[0]'             => 'Você está bem?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
                    'questions[1][options][2]' => 'não',
                }
            )
            ->status_is(400);

            # Create poll with invalid status(non existent id)
            $t->post_ok(
                '/api/register/poll',
                form => {
                    name                       => 'this is a poll without a valid status_id',
                    status_id                  => fake_int(4, 100)->(),
                    'questions[0]'             => 'Você está bem?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
                    'questions[1][options][2]' => 'não',
                }
            )
            ->status_is(400);

            # Create poll with invalid status(string)
            $t->post_ok(
                '/api/register/poll',
                form => {
                    name                       => 'this is a poll without a valid status_id',
                    status_id                  => 'foobar',
                    'questions[0]'             => 'Você está bem?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
                    'questions[1][options][2]' => 'não',
                }
            )
            ->status_is(400);
        };
    };

    subtest 'Politician | Create poll' => sub {
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'Você está bem?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
                'questions[1][options][2]' => 'não',
            }
        )
        ->status_is(201);

        subtest 'Poll status' => sub {
            my $poll = $t->post_ok(
                '/api/register/poll',
                form => {
                    name                       => 'this is the second poll',
                    status_id                  => 2,
                    'questions[0]'             => 'Você está bem?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
                    'questions[1][options][2]' => 'não',
                }
            )
            ->status_is(201);

        };
    };
};

done_testing();


#     rest_post "/api/register/poll",
#         name                => "Create inactive poll",
#         automatic_load_item => 0,
#         stash               => "p2",
#         [
#         ]
#     ;

#     is( $schema->resultset('Poll')->find(stash "p1.id")->status_id, 1, 'first poll is active' );
#     is( $schema->resultset('Poll')->find(stash "p2.id")->status_id, 2, 'second poll is inactive' );

#     rest_post "/api/register/poll",
#         name                => "Create a new active poll",
#         automatic_load_item => 0,
#         stash               => "p3",
#         [
#             name                       => 'this is the third poll',
#             status_id                  => 1,
#             'questions[0]'             => 'Você está bem?',
#             'questions[0][options][0]' => 'Sim',
#             'questions[0][options][1]' => 'Não',
#             'questions[1]'             => 'foobar?',
#             'questions[1][options][0]' => 'foo',
#             'questions[1][options][1]' => 'bar',
#             'questions[1][options][2]' => 'não',
#         ]
#     ;

#     is( $schema->resultset('Poll')->find(stash "p1.id")->status_id, 3, 'first poll is deactivated' );
#     is( $schema->resultset('Poll')->find(stash "p2.id")->status_id, 2, 'second poll is inactive' );
#     is( $schema->resultset('Poll')->find(stash "p3.id")->status_id, 1, 'third poll is active' );
# };

# done_testing();