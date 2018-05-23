use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $chatbot_security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => "foo"
    );
    my $politician_id = stash "politician.id";

    api_auth_as "user_id" => $politician_id;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name                => "Creating Voto Legal integration",
        automatic_load_item => 0,
        [ votolegal_email  => 'demonstracao@votolegal.com.br' ]
    ;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Integration without votolegal_email",
        is_fail => 1,
        code    => 400,
    ;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Integration with non-existent votolegal_email",
        is_fail => 1,
        code    => 400,
        [ votolegal_email => 'thisisonlyatestemail@email.com' ]
    ;

    rest_get "/api/chatbot/politician",
        name  => 'get politician data',
        list  => 1,
        stash => 'get_politician_data',
        [
            security_token => $chatbot_security_token,
            fb_page_id     => 'foo'
        ]
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        my $votolegal_integration = $res->{votolegal_integration};

        is ( $votolegal_integration->{username}, 'josehernandes', 'voto legal username' );
        ok ( defined( $votolegal_integration->{url} ) , 'voto legal url' );
    };

};

done_testing();