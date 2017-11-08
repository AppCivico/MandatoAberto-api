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

    # rest_post "/api/poll/$poll_id/question",
    #     name    => "Poll question without content",
    #     is_fail => 1,
    #     code    => 400,
    # ;

    rest_post "/api/poll/$poll_id/question",
        name                => "Sucessful question creation",
        automatic_load_item => 0,
        stash               => "q1",
        [ content => "Foobar" ]
    ;

    # my $question_id = stash "q1.id";

    # rest_get "/api/poll/$poll_id/question/$question_id",
    #     name => "List question",
    #     list => 1,
    #     stash => "get_question"
    # ;

};

done_testing();