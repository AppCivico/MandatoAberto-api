use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician(
        fb_page_id => 'foobar'
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
        ]
    ;

    my $politician_chatbot = $schema->resultset("PoliticianChatbot")->search( { politician_id => $politician_id } )->next;

    api_auth_as user_id => $politician_chatbot->id;

    my $citizen_fb_id = fake_words(1)->();
    rest_post "/api/chatbot/citizen",
        name                => "create citizen",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => $citizen_fb_id,
            email         => fake_email()->(),
            cellphone     => fake_digits("+551198#######")->(),
            gender        => fake_pick( qw/F M/ )->()
        ]
    ;
    my $citizen_id = stash "c1.id";

    rest_get "/api/chatbot/poll",
        name  => 'get poll',
        list  => 1,
        stash => "get_poll",
        [ fb_page_id => 'foobar' ]
    ;
    my $poll = stash "get_poll";

    my $chosen_option_id = $poll->{questions}->[0]->{options}->[1]->{id};
    my $second_chosen_option_id = $poll->{questions}->[0]->{options}->[0]->{id};

    rest_post "/api/chatbot/poll-result",
        name    => "create poll without option_id",
        is_fail => 1,
        [ fb_id     => $citizen_fb_id ]
    ;

    rest_post "/api/chatbot/poll-result",
        name    => "create poll without fb_id",
        is_fail => 1,
        [ option_id => $chosen_option_id ]
    ;

    rest_post "/api/chatbot/poll-result",
        name    => "create poll with unexistent fb_id",
        is_fail => 1,
        [
            option_id => $chosen_option_id,
            fb_id     => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/poll-result",
        name                => "create poll result",
        automatic_load_item => 0,
        stash               => "c1",
        [
            fb_id     => $citizen_fb_id,
            option_id => $chosen_option_id,
        ]
    ;
};

done_testing();