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
        name    => 'politician greeting without greeting_id',
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name    => 'politician greeting with invalid greeting_id',
        is_fail => 1,
        code    => 400,
        [ greeting_id => 'foobar' ]
    ;

    rest_post "/api/politician/$politician_id/greeting",
        name                => 'politician greeting',
        automatic_load_item => 1,
        stash               => 'g1',
        code                => 200,
        [ greeting_id => 1 ]
    ;

    rest_get "/api/politician/$politician_id/greeting",
        name  => "get politician greeting",
        list  => 1,
        stash => "get_politician_greeting"
    ;

    stash_test "get_politician_greeting" => sub {
        my $res = shift;

        is ($res->{greetings}[0]->{id}, 1, 'first greeting');
        is ($res->{greetings}[0]->{selected}, 1, 'first greeting selected');
        is ($res->{greetings}[1]->{id}, 2, 'second greeting');
        is ($res->{greetings}[1]->{selected}, 0, 'second greeting not selected');
    };

    rest_post "/api/politician/$politician_id/greeting",
        name                => 'politician greeting',
        automatic_load_item => 1,
        stash               => 'g2',
        code                => 200,
        [ greeting_id => 2 ]
    ;

    rest_reload_list "get_politician_greeting";

    stash_test "get_politician_greeting.list" => sub {
        my $res = shift;

        is ($res->{greetings}[0]->{id}, 2, 'second greeting');
        is ($res->{greetings}[0]->{selected}, 1, 'second greeting selected');
        is ($res->{greetings}[1]->{id}, 1, 'first greeting');
        is ($res->{greetings}[1]->{selected}, 0, 'first greeting not selected');
    };
};

done_testing();
