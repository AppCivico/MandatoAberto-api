use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    $politician = $schema->resultset('Politician')->find( $politician->{id} );

    my $politician_id = $politician->id;

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

	my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    subtest 'Chatbot | Create invalid status' => sub {

        rest_post '/api/chatbot/status',
            name    => 'Create status with invalid err_msg format',
            is_fail => 1,
            code    => 400,
            [
                security_token          => $security_token,
                organization_chatbot_id => $organization_chatbot_id,
                err_msg                 => 'foobar'
            ]
        ;

        rest_post '/api/chatbot/status',
            name    => 'Create status with valid access_token and err_msg',
            is_fail => 1,
            code    => 400,
            [
                security_token          => $security_token,
                organization_chatbot_id => $organization_chatbot_id,
                access_token_valid      => 1,
                err_msg                 => encode_json { foo => 'bar' }
            ]
        ;
    };

    subtest 'Chatbot | Create status' => sub {
        rest_post '/api/chatbot/status',
            name                => 'Create status',
            automatic_load_item => 0,
            [
                security_token          => $security_token,
                organization_chatbot_id => $organization_chatbot_id,
                access_token_valid      => 1,
            ]
        ;

        rest_get '/api/chatbot/status',
            name  => 'get status',
            stash => 'get_status',
            list  => 1,
            [
                security_token          => $security_token,
                organization_chatbot_id => $organization_chatbot_id,
            ]
        ;
    }
};

done_testing();