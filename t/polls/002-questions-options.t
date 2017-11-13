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
        [ name => "Foobar" ]
    ;

    my $poll_id = stash "p1.id";

    rest_post "/api/poll/$poll_id/question",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "q1",
        [ content => "Foobar" ]
    ;

    my $question_id = stash "q1.id";

    api_auth_as user_id => 1;

    rest_post "/api/poll/$poll_id/question/$question_id/option",
        name    => "Creating question option as admin",
        is_fail => 1,
        code    => 403,
        [ content => "Foobar" ]
    ;

    api_auth_as user_id => stash "politician.id";

    rest_post "/api/poll/$poll_id/question/$question_id/option",
        name    => "Creating question option without content",
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/poll/$poll_id/question/$question_id/option",
        name    => "Creating question option with more than 20 chars",
        is_fail => 1,
        code    => 400,
        [ content => fake_words(10)->() ]
    ;

    rest_post "/api/poll/$poll_id/question/$question_id/option",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "q1",
        [ content => "Foobar" ]
    ;

    my $option_id = stash "q1.id";

    rest_get "/api/poll/$poll_id/question/$question_id/option/$option_id",
        name  => "get question option",
        list  => 1,
        stash => "get_question_option"
    ;

    stash_test "get_question_option" => sub {
        my $res = shift;

        is ($res->{id}, $option_id, 'option id');
        is ($res->{question_id}, $question_id, 'question id');
        is ($res->{content}, 'Foobar', 'option content');
    };

    rest_put "/api/poll/$poll_id/question/$question_id/option/$option_id",
        name  => "put question option",
        [ content => "Altered" ]
    ;

    rest_reload_list "get_question_option";

    stash_test "get_question_option.list" => sub {
        my $res = shift;

        is ($res->{id}, $option_id, 'option id');
        is ($res->{question_id}, $question_id, 'question id');
        is ($res->{content}, 'Altered', 'option content');
    };

};

done_testing();