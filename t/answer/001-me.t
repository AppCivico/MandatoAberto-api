use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
     create_dialog(
        name => "Test dialog"
    );
    my $dialog_id = stash "dialog.id";

    rest_post "/api/register/question",
        name                => "Creating question",
        stash               => "first_question",
        automatic_load_item => 0,
        [
            dialog_id => $dialog_id,
            name      => "Foobar",
            content   => "What is your answer?"
        ]
    ;

    my $first_question_id = stash "first_question.id";

    rest_post "/api/register/question",
        name                => "Creating another question",
        stash               => "second_question",
        automatic_load_item => 0,
        [
            dialog_id => $dialog_id,
            name      => "Bar",
            content   => "What is your second answer?"
        ]
    ;

    my $second_question_id = stash "second_question.id";


    create_politician;
    my $politician_id = stash "politician.id";
    api_auth_as user_id => $politician_id;

    my $first_question_content = fake_words(1)->();
    rest_post "/api/register/answer",
        name                => "Creating answer",
        stash               => "answer",
        automatic_load_item => 0,
        [
            content     => $first_question_content,
            question_id => $first_question_id
        ]
    ;
    my $first_answer_id = stash "answer.id";

    my $second_question_content = fake_words(1)->();
    rest_post "/api/register/answer",
        name                => "Creating answer",
        stash               => "second_answer",
        automatic_load_item => 0,
        [
            content     => $second_question_content,
            question_id => $second_question_id
        ]
    ;

    rest_get "/api/answer/",
        name => "Get politician answers",
        list => 1,
        stash => "get_politician_answers"
    ;

    stash_test "get_politician_answers" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                answers => [
                    {
                        question_id => $first_question_id,
                        content     => $first_question_content
                    },
                    {
                        question_id => $second_question_id,
                        content     => $second_question_content
                    },
                ]
            },
            'Get politician answers expected response'
        );
    };

    rest_put "/api/answer/$first_answer_id",
        name => "PUT first answer",
        [ content => "Foobar" ]
    ;

    rest_reload_list "get_politician_answers";

    stash_test "get_politician_answers.list" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                answers => [
                    {
                        question_id => $second_question_id,
                        content     => $second_question_content
                    },
                    {
                        question_id => $first_question_id,
                        content     => "Foobar"
                    },
                ]
            },
            'Get updated politician answers expected response'
        );
    };
};

done_testing();