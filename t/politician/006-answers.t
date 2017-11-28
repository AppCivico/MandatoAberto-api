use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => 1;

    create_dialog;
    my $dialog_id = stash "dialog.id";

    rest_post "/api/dialog/$dialog_id/question",
        name                => "question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name          => fake_words(1)->(),
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->()
        ]
    ;
    my $first_question_id = stash "q1.id";

    rest_post "/api/dialog/$dialog_id/question",
        name                => "second question",
        automatic_load_item => 0,
        stash               => "q2",
        [
            name          => fake_words(1)->(),
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->()
        ]
    ;
    my $second_question_id = stash "q2.id";

    rest_post "/api/politician/$politician_id/answers",
        name    => "POST politician answer as admin",
        is_fail => 1,
        code    => 403,
        [
            "question[$first_question_id][answer]" => 'foobar'
        ]
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/answers",
        name    => "Empty answer",
        is_fail => 1,
        code    => 400,
        [ "question[$first_question_id][answer]"  => "" ]
    ;

    my $answer_content = fake_words(1)->();
    rest_post "/api/politician/$politician_id/answers",
        name  => "POST politician answer",
        code  => 200,
        stash => "a1",
        [ "question[$first_question_id][answer]" => $answer_content ]
    ;

    my $answer    = stash "a1";
    my $answer_id = $answer->{answers}->[0]->{id};

    is ($schema->resultset('Answer')->search( { politician_id => $politician_id } )->count, "1", "1 answer created");

    rest_get "/api/politician/$politician_id/answers",
        name  => "GET politician answers",
        list  => 1,
        stash => "get_politician_answers"
    ;

    stash_test "get_politician_answers" => sub {
        my $res = shift;

        is ($res->{answers}->[0]->{id},          $answer_id,         'answer id');
        is ($res->{answers}->[0]->{content},     $answer_content,    'answer content');
        is ($res->{answers}->[0]->{dialog_id},   $dialog_id,         'answer dialog_id');
        is ($res->{answers}->[0]->{question_id}, $first_question_id, 'answer first_question_id');
    };

    rest_post "/api/politician/$politician_id/answers",
        name    => "POST answer with one alredy existing",
        is_fail => 1,
        code    => 400,
        [ "question[$first_question_id][answer]" => $answer_content ]
    ;

    my $fake_id = fake_int(1000000, 9000000)->();
    rest_post "/api/politician/$politician_id/answers",
        name    => "Invalid answer id",
        is_fail => 1,
        code    => 400,
        [ "question[$first_question_id][answer][$fake_id]" => 'foobar' ]
    ;

    rest_post "/api/politician/$politician_id/answers",
        name    => "Invalid answer id with valid",
        is_fail => 1,
        code    => 400,
        [
            "question[$first_question_id][answer][$answer_id]" => 'foobar',
            "question[$first_question_id][answer][$fake_id]" => 'foobar',
        ]
    ;

    rest_reload_list "get_politician_answers";
    stash_test "get_politician_answers.list" => sub {
        my $res = shift;

        is ($res->{answers}->[0]->{id},          $answer_id,         'answer id');
        is ($res->{answers}->[0]->{content},     $answer_content,    'answer content');
        is ($res->{answers}->[0]->{dialog_id},   $dialog_id,         'answer dialog_id');
        is ($res->{answers}->[0]->{question_id}, $first_question_id, 'answer first_question_id');
    };

    rest_post "/api/politician/$politician_id/answers",
        name  => "Update politician answer",
        code  => 200,
        stash => "u1",
        [ "question[$first_question_id][answer][$answer_id]" => 'foobar' ]
    ;

    rest_reload_list "get_politician_answers";
    stash_test "get_politician_answers.list" => sub {
        my $res = shift;

        is ($res->{answers}->[0]->{id},          $answer_id,         'answer id');
        is ($res->{answers}->[0]->{content},     "foobar",           'updated answer content');
        is ($res->{answers}->[0]->{dialog_id},   $dialog_id,         'answer dialog_id');
        is ($res->{answers}->[0]->{question_id}, $first_question_id, 'answer first_question_id');
    };

    rest_post "/api/politician/$politician_id/answers",
        name  => "Update politician answer and create another",
        code  => 200,
        stash => "au1",
        [
            "question[$first_question_id][answer][$answer_id]" => 'FOOBAR',
            "question[$second_question_id][answer]"            => 'appcivico'
        ]
    ;

    my $response      = stash "au1";
    my $second_answer = $response->{answers}->[1];

    rest_reload_list "get_politician_answers";
    stash_test "get_politician_answers.list" => sub {
        my $res = shift;

        is ($res->{answers}->[0]->{id},          $answer_id,         'first answer id');
        is ($res->{answers}->[0]->{content},     "FOOBAR",           'updated first answer content');
        is ($res->{answers}->[0]->{dialog_id},   $dialog_id,         'first answer dialog_id');
        is ($res->{answers}->[0]->{question_id}, $first_question_id, 'first answer first_question_id');

        is ($res->{answers}->[1]->{content},     "appcivico",          'second answer content');
        is ($res->{answers}->[1]->{dialog_id},   $dialog_id,           'second answer dialog_id');
        is ($res->{answers}->[1]->{question_id}, $second_question_id,  'second answer first_question_id');
    };

    create_politician;
    api_auth_as user_id => stash "politician.id";
    rest_post "/api/politician/$politician_id/answers",
        name    => "POST another politician answer",
        is_fail => 1,
        code    => 403,
        [ "question[$first_question_id][answer][$answer_id]" => 'foobar' ]
    ;
};

done_testing();