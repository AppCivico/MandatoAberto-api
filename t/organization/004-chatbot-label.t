use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    my ($user_id, $organization_id, $chatbot_id);
    subtest 'Create chatbot' => sub {
        $user_id         = create_user();
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
    };


    subtest 'User | Create label' => sub {
        api_auth_as user_id => $user_id;

        # Ativando chatbot
        rest_put "/api/organization/$organization_id/chatbot/$chatbot_id",
            code => 200,
            [
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            ]
        ;

        # Criando label
        rest_post "/api/organization/$organization_id/chatbot/$chatbot_id/label",
            automatic_load_item => 0,
            [ name => 'foobar' ]
        ;

        rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/label";
    };
};

done_testing();
