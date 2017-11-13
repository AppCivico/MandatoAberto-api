use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    api_auth_as user_id => 1;
    rest_post "/api/register/poll",
        name    => "Create poll as an admin",
        is_fail => 1,
        code    => 403
    ;

    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/poll",
        name    => "Poll without name",
        is_fail => 1,
        code    => 400
    ;

    my $poll_name = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [ name => $poll_name ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with repeated name",
        is_fail => 1,
        code    => 400,
        [ name => $poll_name ]
    ;
};

done_testing();