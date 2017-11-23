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

    # Um político não pode criar uma pergunta
    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/dialog/$dialog_id/question",
        name    => "Question created by politician",
        is_fail => 1,
        code    => 403,
        [
            name          => $question_name,
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;

    api_auth_as user_id => 1;

    rest_post "/api/dialog/$dialog_id/question",
        name    => "Question without content",
        is_fail => 1,
        code    => 400,
        [
            name          => $question_name,
            citizen_input => fake_words(1)->()
        ]
    ;

    rest_post "/api/dialog/$dialog_id/question",
        name    => "Question without name",
        is_fail => 1,
        code    => 400,
        [
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;

    rest_post "/api/dialog/$dialog_id/question",
        name    => "Question without citizen input",
        is_fail => 1,
        code    => 400,
        [
            content => "Foobar",
            name    => $question_name,
        ]
    ;

    rest_post "/api/dialog/$dialog_id/question",
        name                => "Sucessful question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name          => $question_name,
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;

    my $question_id = stash "q1.id";

    rest_post "/api/dialog/$dialog_id/question",
        name    => "Question name alredy exists",
        is_fail => 1,
        code    => 400,
        [
            name          => $question_name,
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;

    rest_get "/api/dialog/$dialog_id/question/$question_id",
        name  => "GET specific question",
        list  => 1,
        stash => "get_question",
    ;

};

done_testing();