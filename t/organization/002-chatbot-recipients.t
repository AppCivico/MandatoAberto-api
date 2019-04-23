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

    subtest 'User | Get organization' => sub {
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
        use DDP; p $recipient;

        $t->get_ok(
            'organization/$organization_id/chatbot/$chatbot_id/recipients',
            form => {
                security_token => $security_token,

            }
        )

        # rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/recipients",
        #     code  => 200,
        #     stash => 'cl1',
        #     list  => 1
        # ;

        # stash_test 'cl1' => sub {
        #     my $res = shift;

        #     # TODO testar campos do retorno
        # };
    };
};

done_testing();
