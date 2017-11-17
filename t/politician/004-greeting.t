use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/greeting",
      name                => "greeting create",
      code                => 201,
      automatic_load_item => 0,
      stash               => "greet",
      [ text => "Hello. I'm the Mayor!" ],
      ;

    rest_post "/api/politician/$politician_id/greeting",
      name    => "greeting with empty text",
      is_fail => 1,
      code    => 400,
      stash   => "greetFail",
      [ text => "" ],
      ;

    rest_post "/api/politician/$politician_id/greeting",
      name    => "greeting with invalid text length",
      is_fail => 1,
      code    => 400,
      stash   => "greetFail",
      [ text =>
"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      ],
      ;

};

done_testing();
