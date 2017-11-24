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
        name => "POST politician answer",
        code => 200,
        [
            "question[$first_question_id]"  => fake_words(1)->(),
            "question[$second_question_id]" => fake_words(1)->()
        ]
    ;
};

done_testing();