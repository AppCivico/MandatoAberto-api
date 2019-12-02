use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot_id, $recipient_id);
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user();
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
    };


    subtest 'User | Create recipient' => sub {
        api_auth_as user_id => $user_id;

        # Ativando chatbot
        rest_put "/api/organization/$organization_id/chatbot/$chatbot_id",
            code => 200,
            [
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            ]
        ;

        # Recipient com fb_id.
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

        # Criando recipient sem fb_id, só pelo cpf.
        my $res = rest_post "/api/chatbot/recipient",
            code   => 400,
            is_fail => 1,
            params => [
                security_token => $security_token,
                chatbot_id     => $chatbot_id,
            ];

        $res = rest_post "/api/chatbot/recipient",
            code    => 201,
            is_fail => 0,
            params  => [
                security_token => $security_token,
                chatbot_id     => $chatbot_id,
                name           => fake_name()->(),
                cpf            => '62579842039'
            ];

        $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/recipients",
            code  => 200,
            stash => 'cl1',
            list  => 1
        ;
    };
};

done_testing();
