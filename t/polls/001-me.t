use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    api_auth_as user_id => stash "politician.id";

    my $poll_name = fake_words(1)->();

    my $first_option_content  = fake_words(1)->();
    my $second_option_content = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 'Foobar',
            'questions[0][options][0]' => $first_option_content,
            'questions[0][options][1]' => $second_option_content,
        ]
    ;

    my $poll_id = stash "p1.id";

    my $question_id     = $schema->resultset('PollQuestion')->search( { poll_id => $poll_id } )->next->id;

    my $first_option_id = $schema->resultset('QuestionOption')->search(
        {
            question_id => $question_id,
            content     => $first_option_content
        }
    )->next->id;

    my $second_option_id = $schema->resultset('QuestionOption')->search(
        {
            question_id => $question_id,
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
        is ($res->{polls}->[0]->{active}, 1, 'poll active');
        is ($res->{polls}->[0]->{name}, $poll_name, 'poll name');
        is ($res->{polls}->[0]->{questions}->[0]->{content}, 'Foobar', 'question content');
        is ($res->{polls}->[0]->{questions}->[0]->{id}, $question_id, 'question id');
    };


    rest_put "/api/poll/$poll_id",
        name => "Deactivate poll",
        [ active => 0 ]
    ;

    rest_put "/api/poll/$poll_id",
        name    => "Activate poll that has been active before",
        is_fail => 1,
        code    => 400,
        [ active => 1 ]
    ;

    rest_reload_list "get_poll_data";
    stash_test "get_poll_data.list" => sub {
        my $res = shift;

        is ($res->{polls}->[0]->{active}, 0, 'poll not active');
    };
};

done_testing();