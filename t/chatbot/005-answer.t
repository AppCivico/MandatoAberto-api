use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => 1;

    create_dialog(
        name => 'foobar'
    );
    my $dialog_id = stash "dialog.id";

    my $question_name = fake_words(1)->();
    rest_post "/api/dialog/$dialog_id/question",
        name                => "question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name          => $question_name,
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->()
        ]
    ;
    my $question_id = stash "q1.id";

    api_auth_as user_id => $politician_id;

    my $answer_content = fake_words(1)->();
    rest_post "/api/politician/$politician_id/answers",
        name  => "POST politician answer",
        code  => 200,
        stash => "a1",
        [ "question[$question_id][answer]" => $answer_content ]
    ;

    rest_get "/api/chatbot/answer",
        name  => "get politician answers",
        list  => 1,
        stash => "get_politician_answers",
        [
            politician_id => $politician_id,
            question_name => $question_name
        ]
    ;
};

done_testing();