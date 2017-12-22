use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        [
            name          => fake_name()->(),
            fb_id         => "foobar",
            origin_dialog => fake_words(1)->(),
            gender        => fake_pick( qw/M F/ )->(),
            cellphone     => fake_digits("+551198#######")->(),
            email         => fake_email()->(),
            politician_id => $politician_id
        ]
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => 'foobar',
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

    rest_get "/api/politician/$politician_id/dashboard",
        name  => "politician dashboard",
        list  => 1,
        stash => "get_politician_dashboard"
    ;

    stash_test "get_politician_dashboard" => sub {
        my $res = shift;

        is ($res->{citizens}, 1, 'one citizen');
    };

    rest_post "/api/chatbot/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        [
            name          => fake_name()->(),
            fb_id         => "FOOBAR",
            origin_dialog => fake_words(1)->(),
            gender        => fake_pick( qw/M F/ )->(),
            cellphone     => fake_digits("+551198#######")->(),
            email         => fake_email()->(),
            politician_id => $politician_id
        ]
    ;

    rest_reload_list "get_politician_dashboard";

    stash_test "get_politician_dashboard.list" => sub {
        my $res = shift;

        is ($res->{citizens}, 2, 'two citizens');
    };
};

done_testing();