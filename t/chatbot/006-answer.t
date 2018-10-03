use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;

db_transaction {
    ok my $security_token = env('CHATBOT_SECURITY_TOKEN');

    p $security_token;

    ok my $politician = create_politician;
    ok my $politician_id = $politician->{id};

    api_auth_as user_id => 1;

    ok my $dialog = create_dialog(name => 'foobar');
    ok my $dialog_id = $dialog->{id};

    my $question_name = fake_words(1)->();

    $t->post_ok(
        "/api/admin/dialog/$dialog_id/question",
        form => {
            name          => $question_name,
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->()
        }
    )
    ->status_is(201)
    ->json_has('/id');

    ok my $question_id = $t->tx->res->json->{id};

    api_auth_as user_id => $politician_id;
    my $answer_content = fake_words(1)->();

    $t->post_ok(
        "/api/politician/$politician_id/answers",
        form => {"question[$question_id][answer]" => $answer_content }
    )
    ->status_is(200);

    $t->get_ok(
        "/api/chatbot/answer",
        form => {
            politician_id  => $politician_id,
            question_name  => $question_name,
            security_token => $security_token
        }
    )
    ->status_is(200);
};

done_testing();