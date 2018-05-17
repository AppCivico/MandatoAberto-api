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

};

done_testing();