use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    api_auth_as user_id => 1;

    my $question_name = fake_words(1)->();

    create_dialog;
    my $dialog_id = stash "dialog.id";

    rest_post "/api/dialog/$dialog_id/question",
        name                => "question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name    => $question_name,
            content => "Foobar"
        ]
    ;

    my $question_id = stash "q1.id";

    rest_post "/api/dialog/$dialog_id/question/$question_id/answer",
        name    => "An admin cannot create answers",
        is_fail => 1,
        code    => 400,
        [ content => "Yes" ]
    ;

    create_politician;
    my $politician_id = stash "politician.id";
    api_auth_as user_id => $politician_id;

    rest_post "/api/dialog/$dialog_id/question/$question_id/answer",
        name    => "Answer without content",
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/dialog/$dialog_id/question/$question_id/answer",
        name                => "Creating answer",
        automatic_load_item => 0,
        stash               => "a1",
        [ content => "Yes"]
    ;

    my $answer_id = stash "a1.id";

    rest_get "/api/dialog/$dialog_id/question/$question_id/answer/$answer_id",
        name  => "get answer",
        list  => 1,
        stash => "get_answer",
    ;

    stash_test "get_answer" => sub {
        my $res = shift;

        is ($res->{question_id}, $question_id, 'question_id');
        is ($res->{content}, "Yes", 'content');
        is ($res->{id}, $answer_id, 'answer_id');
        is ($res->{politician_id}, $politician_id, 'politician_id');
    };

    rest_put "/api/dialog/$dialog_id/question/$question_id/answer/$answer_id",
        name => "Put answer",
        [ content => "No" ]
    ;

    rest_reload_list "get_answer";

    stash_test "get_answer.list" => sub {
        my $res = shift;

        is ($res->{question_id}, $question_id, 'question_id');
        is ($res->{content}, "No", 'content');
        is ($res->{id}, $answer_id, 'answer_id');
        is ($res->{politician_id}, $politician_id, 'politician_id');
    };

    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_get "/api/dialog/$dialog_id/question/$question_id/answer/$answer_id",
        name    => "Get answer as another politician",
        is_fail => 1,
        code    => 403,
    ;
};

done_testing();