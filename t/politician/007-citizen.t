use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        code                => 200,
        stash               => "c1",
        [
            name          => fake_name()->(),
            fb_id         => "foobar",
            origin_dialog => "enquete"
        ]
    ;

    rest_get "/api/politician/$politician_id/citizen";
};

done_testing();