use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {
	my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user, $user_id, $organization_id, $chatbot_id, $recipient);
    subtest 'Create chatbot and recipient' => sub {
        $user            = create_user();
        $user_id         = $user->id;
        $organization_id = $user->organization->id;
        $chatbot_id      = $user->organization->chatbot->id;
    };

    subtest 'User | Get recipient' => sub {
        api_auth_as user_id => $user_id;

        # Ativando chatbot
        $t->put_ok(
            "/organization/$organization_id/chatbot/$chatbot_id",
            form => {
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            }
        )
        ->status_is('202')
        ->json_has('/id');

        $recipient = create_recipient();

        $t->get_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/recipients",
            form => {
                security_token => $security_token,
            }
        )
        ->status_is(200)
        ->json_is('/itens_count', '1')
        ->json_has('/recipients/0/id')
        ->json_has('/recipients/0/name')
        ->json_has('/recipients/0/groups')
        ->json_has('/recipients/0/intents');

        my $recipient_id = $recipient->id;
        $t->get_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/recipients/$recipient_id",
            form => {
                security_token => $security_token,
            }
        )
        ->status_is(200)
        ->json_has('/id')
        ->json_has('/name')
        ->json_has('/groups')
        ->json_has('/intents');
    };
};

done_testing();
