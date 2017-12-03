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
        [
            name          => "foobar",
            fb_id         => "foobar",
            origin_dialog => "enquete"
        ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message without content",
        is_fail => 1,
        code    => 400
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating direct message",
        automatic_load_item => 0,
        [ content => fake_words(2)->() ]
    ;

    is (
        $schema->resultset("DirectMessage")->search( {
            politician_id => $politician_id,
            sent          => 0
        } )->count
        , '1',
        'one direct message not sent'
    );

    my $direct_message = $schema->resultset("DirectMessage")->search( {
        politician_id => $politician_id,
        sent          => 0
    } )->next;

    is (
        $schema->resultset("DirectMessageQueue")->search( { direct_message_id => $direct_message->id } )->count
        , '1'
        , 'one direct message in the queue'
    );
};

done_testing();