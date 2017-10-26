use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    rest_post "/api/register/question",
        name    => "post without login",
        is_fail => 1,
        code    => 403
    ;

    # Um político não pode criar uma pergunta
    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/question",
        name    => "post made by a politician",
        is_fail => 1,
        code    => 403
    ;

    create_admin_and_auth_as;

    my $question_name = "Foobar";

    rest_post "/api/register/question",
        name    => "Question without dialog_id",
        is_fail => 1,
        code    => 400,
        [
            name    => $question_name,
            content => "Foobar"
        ]
    ;

    rest_post "/api/register/question",
        name    => "Question without name",
        is_fail => 1,
        code    => 400,
        [
            dialog_id => 1,
            content   => "Foobar"
        ]
    ;

    rest_post "/api/register/question",
        name    => "Question without content",
        is_fail => 1,
        code    => 400,
        [
            dialog_id => 1,
            name      => $question_name
        ]
    ;

    rest_post "/api/register/question",
        name    => "Question with non existent dialog_id",
        is_fail => 1,
        code    => 400,
        [
            dialog_id => 1,
            name      => $question_name,
            content   => "Foobar"
        ]
    ;

    create_dialog;
    my $dialog_id = stash "dialog.id";

    rest_post "/api/register/question",
        name                => "Successful question creation",
        automatic_load_item => 0,
        [
            dialog_id => $dialog_id,
            name      => $question_name,
            content   => "Foobar"
        ]
    ;

    rest_post "/api/register/question",
        name    => "Question name alredy exists",
        is_fail => 1,
        code    => 400,
        [
            dialog_id => $dialog_id,
            name      => $question_name,
            content   => "Foobar"
        ]
    ;

};

done_testing();