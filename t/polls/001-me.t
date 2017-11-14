use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    api_auth_as user_id => stash "politician.id";

    my $poll_name = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name => $poll_name,
            'question[0][content]'            => 'Foobar',
            'question[0][option][0][content]' => 'Foobar',
        ]
    ;

    my $poll_id = stash "p1.id";

    my $question_id = $schema->resultset('PollQuestion')->search( { poll_id => $poll_id } )->next->id;
    my $option_id     = $schema->resultset('QuestionOption')->search( { question_id => $question_id } )->next->id;

    rest_get "/api/poll",
        name  => "Get all poll data",
        list  => 1,
        stash => "get_poll_data"
    ;

    stash_test "get_poll_data" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                polls => [
                    {
                        id   => $poll_id,
                        name => $poll_name,

                        questions => [
                            {
                                content => "Foobar",
                                id      => $question_id,

                                options => [
                                    {
                                        content => "Foobar",
                                        id      => $option_id
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            'get poll data expected response'
        );
    };
};

done_testing();