use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    ok( my $chatbot = $schema->resultset("PoliticianChatbot")->
        search( { politician_id => $politician_id } )->next,
        'chatbot ok'
    );

    is ($schema->resultset("PoliticianChatbot")->search( { politician_id => $politician_id } )->count, '1', "chatbot created");
    is ($schema->resultset("UserRole")->search( { user_id => $chatbot->id } )->next->role_id, '3', "chatbot role" );
};

done_testing();