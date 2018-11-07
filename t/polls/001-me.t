use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $politician = create_politician;
    api_auth_as user_id => $politician->{id};

    my $poll_name = fake_words(1)->();

    my $first_option_content  = fake_words(1)->();
    my $second_option_content = fake_words(1)->();

    my $poll_id;
    subtest 'Politician | Create poll' => sub {
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'Foobar',
                'questions[0][options][0]' => $first_option_content,
                'questions[0][options][1]' => $second_option_content,
            }
        )
        ->status_is(201)
        ->json_has('/id');

        $poll_id = $t->tx->res->json->{id};
    };

    my $question_id = $schema->resultset('PollQuestion')->search( { poll_id => $poll_id } )->next->id;

    my $first_option_id = $schema->resultset('PollQuestionOption')->search(
        {
            poll_question_id => $question_id,
            content          => $first_option_content
        }
    )->next->id;

    my $second_option_id = $schema->resultset('PollQuestionOption')->search(
        {
            poll_question_id => $question_id,
            content     => $second_option_content
        }
    )->next->id;

    subtest 'Politician | Get and edit poll' => sub {
        $t->get_ok('/api/poll')
          ->status_is(200)
          ->json_has('/polls')
          ->json_is('/polls/0/id',                  $poll_id,     'poll id')
          ->json_is('/polls/0/status_id',           1,            'poll status_id')
          ->json_is('/polls/0/name',                $poll_name,   'poll name')
          ->json_is('/polls/0/questions/0/content', 'Foobar',     'question content')
          ->json_is('/polls/0/questions/0/id',      $question_id, 'question id');

        # set poll to inactive
        $t->put_ok(
            "/api/poll/$poll_id",
            form => {
                status_id => 2
            }
        )
        ->status_is(400);

        # Deactivate poll
        $t->put_ok(
            "/api/poll/$poll_id",
            form => {
                status_id => 3
            }
        )
        ->status_is(202);

        # Activate poll that has been activated before
        $t->put_ok(
            "/api/poll/$poll_id",
            form => {
                status_id => 1
            }
        )
        ->status_is(400);

        $t->get_ok('/api/poll')
          ->status_is(200)
          ->json_is('/polls/0/status_id', 3, 'poll deactivated');
    };
};

done_testing();