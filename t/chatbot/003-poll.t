use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician(
        fb_page_id => "foobar"
    );
    my $politician_id = stash "politician.id";
    api_auth_as user_id => $politician_id;

    my $poll_name = fake_words(1)->();
    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        [
            name                       => $poll_name,
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;

    my $politician_chatbot = $schema->resultset("PoliticianChatbot")->search( { politician_id => $politician_id } )->next;

    api_auth_as user_id => $politician_chatbot->id;

    rest_get "/api/chatbot/poll",
        name  => 'get poll',
        list  => 1,
        stash => "get_poll",
        [ fb_page_id => 'foobar' ]
    ;
};

done_testing();