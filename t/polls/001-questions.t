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
        name    => "Poll question without content",
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/poll/$poll_id/question",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "q1",
        [ content => "Foobar" ]
    ;

    my $question_id = stash "q1.id";

    api_auth_as user_id => 1;

    rest_get "/api/poll/$poll_id/question/$question_id",
        name    => "get poll question as an admin",
        is_fail => 1,
        code    => 403,
    ;

    rest_put "/api/poll/$poll_id/question/$question_id",
        name    => "put poll question as an admin",
        is_fail => 1,
        code    => 403,
        [ content => "Altered" ]
    ;

    api_auth_as user_id => stash "politician.id";

    rest_get "/api/poll/$poll_id/question/$question_id",
        name  => "get poll question",
        list  => 1,
        stash => "get_poll_question"
    ;

    stash_test "get_poll_question" => sub {
        my $res = shift;

        is ($res->{id}, $question_id, 'poll question id');
        is ($res->{poll_id}, $poll_id, 'poll id');
        is ($res->{content}, "Foobar", 'poll question content');
    };

    rest_put "/api/poll/$poll_id/question/$question_id",
        name    => "put poll question",
        [ content => "Altered" ]
    ;

    rest_reload_list "get_poll_question";

    stash_test "get_poll_question.list" => sub {
        my $res = shift;

        is ($res->{id}, $question_id, 'poll question id');
        is ($res->{poll_id}, $poll_id, 'poll id');
        is ($res->{content}, "Altered", 'poll question content');
    };

    rest_get "/api/poll/",
        name     => "get poll question",
    ;

    # Um politico não pode ver nem alterar os dados de enquete de outro
    # create_politician;
    # api_auth_as user_id => stash "politician.id";
};

done_testing();