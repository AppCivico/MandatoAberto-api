use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        fb_page_id => "foobar"
    );
    my $politician_id = $politician->{id};
    api_auth_as user_id => $politician_id;

    my $poll_name = fake_words(1)->();

    subtest 'Politician | Create poll' => sub {
        $t->post_ok(
            '/api/register/poll',
            form => {
                name                       => $poll_name,
                status_id                  => 1,
                'questions[0]'             => 'Você está bem?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
                'questions[1][options][2]' => 'não',
            }
        )
        ->status_is(201);
    };

    subtest 'Chatbot | Get poll' => sub {
        $t->get_ok(
            '/api/chatbot/poll',
            form => {
                fb_page_id     => 'foobar',
                security_token => $security_token
            }
        )
        ->status_is(200)
		->json_has('/id')
		->json_has('/name')
		->json_has('/questions')
		->json_has('/questions/0/id')
		->json_has('/questions/0/content')
		->json_has('/questions/0/options');
    };
};

done_testing();