use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
	my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

	create_politician(
		fb_page_id           => fake_words(1)->(),
		fb_page_access_token => fake_words(1)->()
	);
	my $politician    = $schema->resultset('Politician')->find(stash 'politician.id');
	my $politician_id = $politician->id;

	create_recipient( politician_id => $politician_id );
	my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    # Criando entrada de knowledge-base
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
            message        => 'Como faço para me vacinar?',
            security_token => $security_token,
            entities       => encode_json(
                {
                    Saude => [
                        'posto de saúde',
                        'vacinacao',
                    ]
                }
            )
        ]
    ;
    my $issue_id = stash "i1.id";

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient->fb_id,
            message        => 'O que você acha sobre o aborto?',
            security_token => $security_token,
            entities       => encode_json(
                {
                    Aborto => [
                        'aborto',
                    ]
                }
            )
        ]
    ;
    my $second_issue_id = stash "i2.id";

    api_auth_as user_id => $politician_id;

    my $question = fake_sentences(1)->();
    my $answer   = fake_sentences(2)->();

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            issue_id => $issue_id,
            answer   => 'foobar',
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name  => 'creating knowledge base entry',
        stash => 'k2',
        [
            issue_id => $second_issue_id,
            answer   => 'posicionamento sobre o aborto',
        ]
    ;

    rest_get '/api/chatbot/knowledge-base',
        name  => 'get knowledge base',
        stash => 'get_knowledge_base',
        list  => 1,
        [
            security_token => $security_token,
            politician_id  => $politician_id,
            entities       => encode_json(
                {
                    Saude => [
                        'vacinacao',
                        'posto de saúde',
                    ],
                    Aborto => [ 'aborto' ]
                }
            )
        ]
    ;

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 2, '2 rows' )
    }
};

done_testing();