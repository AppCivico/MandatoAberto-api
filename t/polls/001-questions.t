use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/poll",
        name  => "Sucessful poll creation",
        stash => "p1",
        code  => 200
    ;

    my $poll = stash "p1";

    rest_post "/api/register/poll-question",
        name    => "Poll question without poll id",
        is_fail => 1,
        code    => 400,
        [ content => "Foobar" ]
    ;

    rest_post "/api/register/poll-question",
        name    => "Poll question without content",
        is_fail => 1,
        code    => 400,
        [ poll_id => $poll->{id} ]
    ;

    rest_post "/api/register/poll-question",
        name  => "Sucessful poll question creation",
        stash => "pq1",
        [
            poll_id => $poll->{id},
            content => "Foobar"
        ]
    ;
};

done_testing();