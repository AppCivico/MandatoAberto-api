use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
    ;

    my $poll_id = stash "p1.id";

    rest_post "/api/poll/$poll_id/question",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "q1",
        [ content => "Foobar" ]
    ;

    my $question_id = stash "q1.id";

    rest_post "/api/poll/$poll_id/question/$question_id/option",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "o1",
        [ content => "Foobar" ]
    ;

    my $option_id = stash "o1.id";

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
                        id => $poll_id,

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