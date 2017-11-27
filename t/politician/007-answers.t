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
            "question[$first_question_id]" => 'foobar'
        ]
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/answers",
        name    => "Empty answer",
        is_fail => 1,
        code    => 400,
        [ "question[$first_question_id]"  => "" ]
    ;

    rest_post "/api/politician/$politician_id/answers",
        name  => "POST politician answer",
        code  => 200,
        stash => "q1",
        [
            "question[$first_question_id]"  => fake_words(1)->(),
            "question[$second_question_id]" => fake_words(1)->()
        ]
    ;

    my $answers = stash "q1";

    use DDP;

    my $first_answer  = $answers->{answers}->[0];
    my $second_answer = $answers->{answers}->[1];

    rest_post "/api/politician/$politician_id/answers",
        name    => "Answer for same question",
        is_fail => 1,
        code    => 400,
        [ "question[$first_question_id]" => fake_words(1)->() ]
    ;

    rest_get "/api/politician/$politician_id/answers",
        name  => "GET politician answers",
        list  => 1,
        stash => "get_politician_answers"
    ;

    my $first_get_answers = stash "get_politician_answers";

    is (scalar(@{ $first_get_answers->{answers} }), 2, "two answers");

    my $second_answer_id = $second_answer->{id};
};

done_testing();