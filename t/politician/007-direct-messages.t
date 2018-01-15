use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        [
            name          => "foobar",
            politician_id => $politician_id,
            fb_id         => "foobar",
            origin_dialog => "enquete"
        ]
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "Politician not premium",
        is_fail => 1,
        code    => 400,
        [
            name    => "Foobar",
            content => fake_words(2)->(),
        ]
    ;

    ok( $schema->resultset('Politician')->find($politician_id)->update( { premium => 1 } ) , 'politician premium');

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message without content",
        is_fail => 1,
        code    => 400,
        [ name => "foobar" ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message without name",
        is_fail => 1,
        code    => 400,
        [ content => fake_words(2)->() ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating direct message",
        automatic_load_item => 0,
        [
            content => fake_words(2)->(),
            name    => "Mensagem Bacana"
        ];

    is(
        $schema->resultset("DirectMessage")->search(
            {
                politician_id => $politician_id,
                sent          => 0
            }
          )->count,
        '1',
        'one direct message not sent'
    );

    my $direct_message = $schema->resultset("DirectMessage")->search(
        {
            politician_id => $politician_id,
            sent          => 0
        }
    )->next;

    is( $schema->resultset("DirectMessageQueue")->search( { direct_message_id => $direct_message->id } )->count,
        '1', 'one direct message in the queue' );

    rest_get "/api/politician/$politician_id/direct-message",
      name => "search politician direct messages",
      list => 1,
      ;
};

done_testing();
