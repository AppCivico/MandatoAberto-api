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
      name => "politician contact as admin",
      ;
};

done_testing();
