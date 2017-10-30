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
        stash               => "question",
        automatic_load_item => 0,
        [
            dialog_id => $dialog_id,
            name      => "Foobar",
            content   => "What is your answer?"
        ]
    ;

    my $question_id = stash "question.id";

    rest_post "/api/register/answer",
        name    => "An admin cannot create answers",
        is_fail => 1,
        code    => 403,
        [
            content     => "Yes",
            question_id => $question_id
        ]
    ;

    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/answer",
        name    => "Answer without content",
        is_fail => 1,
        code    => 400,
        [ question_id => $question_id ]
    ;

    rest_post "/api/register/answer",
        name    => "Answer without question_id",
        is_fail => 1,
        code    => 400,
        [ content     => "Yes" ]
    ;

    rest_post "/api/register/answer",
        name    => "Answer with unexistent question_id",
        is_fail => 1,
        code    => 400,
        [
            content     => "Yes",
            question_id => 9999999
        ]
    ;

    rest_post "/api/register/answer",
        name                => "Creating answer",
        automatic_load_item => 0,
        [
            content     => "Yes",
            question_id => $question_id
        ]
    ;
};

done_testing();