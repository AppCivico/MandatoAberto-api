use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {

	my ($user, $user_id, $organization_id, $chatbot_id, $recipient);
	subtest 'Setup' => sub {
		$user            = create_user();
		$user_id         = $user->id;
		$organization_id = $user->organization->id;
		$chatbot_id      = $user->organization->chatbot->id;

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
	};

    subtest 'User | Create poll (errors)' => sub {
        # Poll sem nome
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
                'questions[0]'             => 'Você está bem?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
                'questions[1][options][2]' => 'não',
            }
        )
        ->status_is('400')
        ->json_is('/error', 'form_error');

        # Poll com modelo de perguntas inválido
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
                name                       => 'foobar',
                'questions[0]'             => 1,
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][0]' => 'Não',
            }
        )
        ->status_is('400');

        # Poll com apenas a pergunta, sem opções de resposta
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
                name           => 'foobar',
                'questions[0]' => 'Você está bem?',
            }
        )
        ->status_is('400');

        # Poll com apenas uma opção de resposta
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
                name                       => 'foobar',
                'questions[0]'             => 'foobar',
                'questions[0][options][0]' => 'Sim',
            }
        )
        ->status_is('400');

        # Poll uma opção de resposta com mais de 20 chars
        # Essa limitação existe, pois o quick reply do Facebook só aceita até 20 chars
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
                name                       => 'foobar',
                'questions[0]'             => 'foobar',
                'questions[0][options][0]' => 'This is a string with more than 20 chars',
	        }
        )
        ->status_is('400');

    };

    subtest 'User | Create poll' => sub {
        $t->post_ok(
            "/organization/$organization_id/chatbot/$chatbot_id/poll",
            form => {
				name                       => 'foobar',
                'questions[0]'             => 'Você está bem?',
                'questions[0][options][0]' => 'Sim',
                'questions[0][options][1]' => 'Não',
                'questions[1]'             => 'foobar?',
                'questions[1][options][0]' => 'foo',
                'questions[1][options][1]' => 'bar',
                'questions[1][options][2]' => 'não',
            }
        )
        ->status_is('201')
        ->json_has('/id');

        db_transaction{
            # Poll com nome repetido
            $t->post_ok(
                "/organization/$organization_id/chatbot/$chatbot_id/poll",
                form => {
                    name                       => 'foobar',
                    'questions[0]'             => 'Você está bem?',
                    'questions[0][options][0]' => 'Sim',
                    'questions[0][options][1]' => 'Não',
                    'questions[1]'             => 'foobar?',
                    'questions[1][options][0]' => 'foo',
                    'questions[1][options][1]' => 'bar',
                    'questions[1][options][2]' => 'não',
                }
            )
            ->status_is('400')
        }
    };

    subtest 'User | List poll' => sub {
        $t->get_ok(

        )
        ->status_is(200)
    };
};

done_testing();
