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
      stash               => "c1",
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

    my $greeting_id = stash "c1.id";

    rest_get "/api/politician/$politician_id/greeting",
      name  => "get politician greeting",
      list  => 1,
      stash => "get_politician_greeting";

    stash_test "get_politician_greeting" => sub {
        my $res = shift;

        is( $res->{politician_greeting}->{id},            $greeting_id,   'greeting_id ok' );
        is( $res->{politician_greeting}->{politician_id}, $politician_id, 'politician_id ok' );
        like( $res->{politician_greeting}->{text}, qr/Hello. I'm the Mayor!/, 'text ok' );
    };

=put que não deu certo
    rest_put "/api/politician/$politician_id/greeting/$greeting_id",
      name                => "PUT sucessfuly",
      automatic_load_item => 0,
      code                => 201,
      stash               => "c1",
      [ text => "Hello. I'm your soon-to-be Mayor!" ];
=cut

};

done_testing();
