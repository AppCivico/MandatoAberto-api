use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => 'foo'
    );

    subtest 'Chatbot | Without security token' => sub {
        $t->get_ok('/api/chatbot/')->status_is(403);
    };

	subtest 'Chatbot | With wrong security token' => sub {
		$t->get_ok(
            '/api/chatbot/',
            form => {
                security_token => fake_words(3)->()
            }
        )
        ->status_is(403);
	};


	subtest 'Chatbot | With correct security token' => sub {
		$t->get_ok(
            '/api/chatbot/',
            form => {
                security_token => $security_token,
                fb_page_id     => 'foo'
            }
        )
        ->status_is(200);
	};
};

done_testing();