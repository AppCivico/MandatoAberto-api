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

        is_deeply(
            $res,
            {
                polls => [
                    {
                        id     => $poll_id,
                        name   => $poll_name,
                        active => 1,

                        questions => [
                            {
                                content => "Foobar",
                                id      => $question_id,

                                options => [
                                    {
                                        content => $first_option_content,
                                        id      => $first_option_id
                                    },
                                    {
                                        content => $second_option_content,
                                        id      => $second_option_id
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

    rest_post "/api/register/poll",
        name    => "Creating second poll",
        [
            name                       => 'foobar',
            active                     => 1,
            'questions[0]'             => 'Foobar',
            'questions[0][options][0]' => $first_option_content,
            'questions[0][options][1]' => $second_option_content,
        ]
    ;

    rest_put "/api/poll/$poll_id",
        name => "PUT poll",
        [
            active => 0
        ]
    ;

    # TODO testar array ordenada
    rest_reload_list "get_poll_data";
    stash_test "get_poll_data.list" => sub {
        my $res        = shift;
        my @sorted_res = sort { $a->{id} <=> $b->{id} } @{ $res->{polls} };
        use DDP; p $poll_id;

        is_deeply(
            [ sort { $a->{id} <=> $b->{id} } @{ $res->{polls} } ],
            [
                {
                    polls => [
                        {
                            [0] => {
                            active    => 0,
                            id        => $poll_id,
                            name      => $poll_name,
                            questions => [
                                [0] => {
                                    content => $first_option_content,
                                    id      => $first_option_id
                                },
                                [1] => {
                                    content => $second_option_content,
                                    id      => $second_option_id
                                }
                            ]
                            }
                        }
                    ]
                }
            ],
            'get poll data updated expected response'
        );
    };
};

done_testing();