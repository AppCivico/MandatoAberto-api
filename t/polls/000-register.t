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
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1"
    ;
};

done_testing();