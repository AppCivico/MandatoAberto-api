use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician();
    my $politician_id = stash "politician.id";

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
    my $poll_id = stash "p1.id";

    rest_get "/api/politician/$politician_id/poll",
        name  => "list polls and respective questions",
        list  => 1,
        stash => "get_polls"
    ;

    stash_test "get_polls" => sub {
        my $res = shift;

        is ($res->{polls}->[0]->{name}, 'foobar', 'poll name');
        is ($res->{polls}->[0]->{status_id}, '1', 'poll status');
    };

    my $question_id = $schema->resultset('PollQuestion')->search( { poll_id => $poll_id } )->next->id;
    rest_get "/api/politician/$politician_id/poll/$poll_id/questions/$question_id";
};

done_testing();