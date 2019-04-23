use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user, $user_id, $organization_id, $chatbot_id, $recipient_id);
    subtest 'Create chatbot and recipient' => sub {
        $user            = create_user();
        $user_id         = $user->id;
        $organization_id = $user->organization->id;
        $chatbot_id      = $user->organization->chatbot->id;

		api_auth_as user_id => $user_id;

        $t->put_ok(
            "/organization/$organization_id/chatbot/$chatbot_id",
            form => {
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            }
        )
        ->status_is('202')
        ->json_has('/id');
    };

    subtest 'Chatbot | Security token' => sub {
        # Sem security_token
        $t->post_ok(
            '/chatbot/recipient',
            form => {
                page_id => 'fake_page_id',
                fb_id   => 'fake_fb_id',
                name    => 'foobar'
            }
        )
        ->status_is(400)
        ->json_is('/error',                     'form_error')
        ->json_is('/form_error/security_token', 'missing');

        # Com security_token inválido
        $t->post_ok(
            '/chatbot/recipient',
            form => {
                security_token => 'random security token',
                page_id        => 'fake_page_id',
                fb_id          => 'fake_fb_id',
                name           => 'foobar'
            }
        )
        ->status_is(403);
    };
};

done_testing();