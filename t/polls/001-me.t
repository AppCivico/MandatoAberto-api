use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    api_auth_as user_id => stash "politician.id";
    activate_chatbot($politician_id);

    my $poll_name = fake_words(1)->();

    my $first_option_content  = fake_words(1)->();
    my $second_option_content = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => $poll_name,
            status_id                  => 1,
            'questions[0]'             => 'Foobar',
            'questions[0][options][0]' => $first_option_content,
            'questions[0][options][1]' => $second_option_content,
        ]
    ;

    my $poll_id = stash "p1.id";

    my $question_id     = $schema->resultset('PollQuestion')->search( { poll_id => $poll_id } )->next->id;

    my $first_option_id = $schema->resultset('PollQuestionOption')->search(
        {
            poll_question_id => $question_id,
            content          => $first_option_content
        }
    )->next->id;

    my $second_option_id = $schema->resultset('PollQuestionOption')->search(
        {
            poll_question_id => $question_id,
            content     => $second_option_content
        }
    )->next->id;

    rest_get "/api/poll",
        name  => "Get all poll data",
        list  => 1,
        stash => "get_poll_data"
    ;

    stash_test "get_poll_data" => sub {
        my $res = shift;

        is ($res->{polls}->[0]->{id}, $poll_id, 'poll id');
        is ($res->{polls}->[0]->{status_id}, 1, 'poll status_id');
        is ($res->{polls}->[0]->{name}, $poll_name, 'poll name');
        is ($res->{polls}->[0]->{questions}->[0]->{content}, 'Foobar', 'question content');
        is ($res->{polls}->[0]->{questions}->[0]->{id}, $question_id, 'question id');
    };

    rest_put "/api/poll/$poll_id",
        name    => "set poll to inactive",
        is_fail => 1,
        code    => 400,
        [ status_id => 2 ]
    ;

    rest_put "/api/poll/$poll_id",
        name => "Deactivate poll",
        [ status_id => 3 ]
    ;

    rest_put "/api/poll/$poll_id",
        name    => "Activate poll that has been activated before",
        is_fail => 1,
        code    => 400,
        [ status_id => 1 ]
    ;

    rest_reload_list "get_poll_data";
    stash_test "get_poll_data.list" => sub {
        my $res = shift;

        is ($res->{polls}->[0]->{status_id}, 3, 'poll deactivated');
    };
};

done_testing();
