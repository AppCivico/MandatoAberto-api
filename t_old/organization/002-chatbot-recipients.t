use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    my ($user_id, $organization_id, $chatbot_id, $recipient_id);
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user();
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
    };


    subtest 'User | Get organization' => sub {
        api_auth_as user_id => $user_id;

        # Ativando chatbot
        rest_put "/api/organization/$organization_id/chatbot/$chatbot_id",
            code => 200,
            [
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            ]
        ;

        $recipient_id = create_recipient(chatbot_id => $chatbot_id);

        rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/recipients",
            code  => 200,
            stash => 'cl1',
            list  => 1
        ;

        stash_test 'cl1' => sub {
            my $res = shift;

            # TODO testar campos do retorno
        };
    };
};

done_testing();
