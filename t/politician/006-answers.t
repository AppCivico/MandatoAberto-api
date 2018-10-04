use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $politician    = create_politician;
    my $politician_id = $politician->{id};

    my $first_question_id;
    my $second_question_id;
    my $dialog_id;
    subtest 'Question | create' => sub {

        api_auth_as user_id => 1;

        my $dialog    = create_dialog;
        $dialog_id = $dialog->{id};

        $t->post_ok(
            "/api/admin/dialog/$dialog_id/question",
            form => {
                name          => fake_words(1)->(),
                content       => fake_words(1)->(),
                citizen_input => fake_words(1)->()
            }
        )
        ->status_is(201);
        #->header_like(Location => qr{/api/admin/dialog/[0-9]+/question/[0-9]+$});

        $first_question_id = $t->tx->res->json->{id};

        $t->post_ok(
           "/api/admin/dialog/$dialog_id/question",
           form => {
               name          => fake_words(1)->(),
               content       => fake_words(1)->(),
               citizen_input => fake_words(1)->()
           },
        )
        ->status_is(201);
        $second_question_id = $t->tx->res->json->{id};
    };

    subtest 'Answers | CRUD' => sub {

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer]" => 'foobar' }
        )
        ->status_is(403);

        api_auth_as user_id => $politician_id;

        my $answer_content = fake_words(1)->();
        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer]" => $answer_content },
        )
        ->status_is(200);

        ok my $answer_id = $t->tx->res->json->{answers}->[0]->{id};

        is $schema->resultset('Answer')->search( { 'me.politician_id' => $politician_id } )->count, '1', '1 answer created';

        $t->get_ok("/api/politician/$politician_id/answers")
        ->status_is(200)
        ->json_is('/answers/0/id',          $answer_id,         'answer id')
        ->json_is('/answers/0/content',     $answer_content,    'answer content')
        ->json_is('/answers/0/dialog_id',   $dialog_id,         'answer dialog_id')
        ->json_is('/answers/0/question_id', $first_question_id, 'answer first_question_id');

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer]" => $answer_content }
        )
        ->status_is(400);

        my $fake_id = fake_int(1000000, 9000000)->();

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer][$fake_id]" => 'foobar' }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => {
                "question[$first_question_id][answer][$answer_id]" => 'foobar',
                "question[$first_question_id][answer][$fake_id]"   => 'foobar',
            }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer][$answer_id]" => '' }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/answers")
        ->json_is('/answers/0/id',          $answer_id,         'answer id')
        ->json_is('/answers/0/content',     $answer_content,    'answer content')
        ->json_is('/answers/0/dialog_id',   $dialog_id,         'answer dialog_id')
        ->json_is('/answers/0/question_id', $first_question_id, 'answer first_question_id');

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer][$answer_id]" => 'foobar' }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/answers")
        ->json_is('/answers/0/id',          $answer_id,         'answer id')
        ->json_is('/answers/0/content',     "foobar",           'updated answer content')
        ->json_is('/answers/0/dialog_id',   $dialog_id,         'answer dialog_id')
        ->json_is('/answers/0/question_id', $first_question_id, 'answer first_question_id');

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => {
                "question[$first_question_id][answer][$answer_id]" => 'FOOBAR',
                "question[$second_question_id][answer]"            => 'appcivico'
            },
        )
        ->status_is(200);

        my $response      = $t->tx->res->json;
        my $second_answer = $response->{answers}->[1];

        $t->get_ok("/api/politician/$politician_id/answers")
        ->json_is('/answers/0/id',          $answer_id,         'first answer id')
        ->json_is('/answers/0/content',     "FOOBAR",           'updated first answer content')
        ->json_is('/answers/0/dialog_id',   $dialog_id,         'first answer dialog_id')
        ->json_is('/answers/0/question_id', $first_question_id, 'first answer first_question_id')
        ->json_is('/answers/1/content',     "appcivico",          'second answer content')
        ->json_is('/answers/1/dialog_id',   $dialog_id,           'second answer dialog_id')
        ->json_is('/answers/1/question_id', $second_question_id,  'second answer first_question_id');

        create_politician;
        api_auth_as user_id => $t->tx->res->json->{id};
        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$first_question_id][answer][$answer_id]" => 'foobar' }
        )
        ->status_is(403);
    };
};

done_testing();