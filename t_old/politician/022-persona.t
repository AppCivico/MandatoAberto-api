use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use DateTime;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;

    rest_put "/api/politician/$politician_id",
        name => 'activate chatbot',
        [
            fb_page_id           => 'foobar',
            fb_page_access_token => 'foobarz'
        ]
    ;

    subtest 'Politician | Create persona' => sub {
        rest_post "/api/politician/$politician_id/persona",
            name                => 'create persona',
            automatic_load_item => 0,
            is_fail             => 0,
            [
                name        => 'foobar',
                picture_url => 'www.foobar.com'
            ]
    };

    subtest 'Politician | Get persona' => sub {
        rest_get "/api/politician/$politician_id/persona",
            name  => 'get persona',
            stash => 'get_persona',
            code  => 200
        ;

        stash_test 'get_persona' => sub {
            my $res = shift;

        }
    };

};

done_testing();