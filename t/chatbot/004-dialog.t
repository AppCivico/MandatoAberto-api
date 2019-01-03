use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician;
    my $politician_id = $politician->{id};

    api_auth_as user_id => 1;

    my $dialog = create_dialog(
        name => 'foobar'
    );
    my $dialog_id = $dialog->{id};

    my $question_id;
    subtest 'Admin | Create question' => sub {
        $t->post_ok(
            "/api/admin/dialog/$dialog_id/question",
            form => {
                name           => fake_words(1)->(),
                content        => fake_words(1)->(),
                citizen_input  => fake_words(1)->(),
                security_token => $security_token
            }
        )
        ->status_is(201);

        $question_id = $t->tx->res->json->{id};
    };

    my $answer_content = fake_words(1)->();
    subtest 'Politician | Create answers' => sub {
        api_auth_as user_id => $politician_id;

        $t->post_ok(
            "/api/politician/$politician_id/answers",
            form => { "question[$question_id][answer]" => $answer_content }
        )
        ->status_is(200);
    };

    subtest 'Chatbot | Get answers' => sub {
        $t->get_ok(
            '/api/chatbot/dialog',
            form => {
                politician_id => $politician_id,
                dialog_name   => 'foobar',
                security_token => $security_token
            }
        )
        ->status_is(200)
        ->json_has('/id')
        ->json_has('/questions')
        ->json_has('/questions/0/id')
        ->json_has('/questions/0/name')
        ->json_has('/questions/0/content')
        ->json_has('/questions/0/citizen_input')
        ->json_has('/questions/0/answer')
        ->json_has('/questions/0/answer/id')
        ->json_has('/questions/0/answer/content')
        ->json_is('/questions/0/answer/content', $answer_content, 'answer content');
    };
};

done_testing();