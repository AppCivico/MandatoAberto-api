use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
        [
            origin_dialog  => fake_words(1)->(),
            politician_id  => $politician_id,
            name           => fake_name()->(),
            fb_id          => $recipient_fb_id,
            email          => fake_email()->(),
            cellphone      => fake_digits("+551198#######")->(),
            gender         => fake_pick( qw/F M/ )->(),
            security_token => $security_token
        ]
    ;
    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

	# Criando a entidade
	my $entity = $schema->resultset('Entity')->create( { name => 'Saúde' } );
	my $politician_entity = $schema->resultset('PoliticianEntity')->create(
		{
			politician_id   => $politician_id,
			entity_id       => $entity->id,
			recipient_count => 1,
		}
	);
    my $politician_entity_id = $politician_entity->id;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => $message,
            security_token => $security_token,
            entities       => "[$politician_entity_id]"
        ]
    ;
    my $issue_id = stash "i1.id";

	$recipient->update( { entities => [$politician_entity_id] } );

    api_auth_as user_id => $politician_id;

    my $question = fake_sentences(1)->();
    my $answer   = fake_sentences(2)->();

    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry without intents (entities)',
        is_fail => 1,
        code    => 400,
        [
            issue_id => $issue_id,
            question => $question,
            answer   => $answer,
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry without question',
        is_fail => 1,
        code    => 400,
        [
            issue_id => $issue_id,
            answer   => $answer,
            entities => "[$politician_entity_id]"
        ]
    ;


    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry without answer',
        is_fail => 1,
        code    => 400,
        [
            issue_id => $issue_id,
			question => $question,
            entities => "[$politician_entity_id]"
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry with invalid issue_id',
        is_fail => 1,
        code    => 400,
        [
            issue_id => 9999999,
			question => $question,
			answer   => $answer,
            entities => "[$politician_entity_id]"
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name    => 'creating knowledge base entry with invalid entity',
        is_fail => 1,
        code    => 400,
        [
            issue_id => 9999999,
			question => $question,
			answer   => $answer,
            entities => '[999999999]'
        ]
    ;

    rest_post "/api/politician/$politician_id/knowledge-base",
        name                => 'creating knowledge base entry',
        automatic_load_item => 0,
        stash               => 'k1',
        [
            issue_id => $issue_id,
			question => $question,
            entities => "[$politician_entity_id]",
            answer   => $answer,
        ]
    ;
    my $kb_id = stash 'k1.id';

    rest_get "/api/politician/$politician_id/knowledge-base",
        name  => 'get politician knowledge base entry (list)',
        stash => 'get_knowledge_base',
        list  => 1
    ;

    stash_test 'get_knowledge_base' => sub {
        my $res = shift;

        is ( scalar @{ $res->{knowledge_base} }, 1, 'one item in the array' );
    };

    rest_get "/api/politician/$politician_id/knowledge-base/$kb_id",
        name  => 'get politician knowledge base entry (result)',
        stash => 'get_knowledge_base_entry',
        list  => 1,
    ;

    stash_test 'get_knowledge_base_entry' => sub {
        my $res = shift;

        my $issues  = $res->{issues};
        my $entities = $res->{entities};

        is ( $res->{active},             1,                     'is active' );
        is ( $res->{question},           $question,             'question' );
        is ( $res->{answer},             $answer,               'answer' );
        is ( defined $res->{created_at}, 1,                     'created_at is defined' );
        is ( ref $entities,              'ARRAY',               'entities is an array' );
        is ( ref $issues,                'ARRAY',               'issues is an array' );
        is ( $issues->[0],               $issue_id,             'issue id' );
        is ( $entities->[0],             $politician_entity_id, 'entity id' );
    };

    rest_put "/api/politician/$politician_id/knowledge-base/$kb_id",
        name => 'update politician knowledge base entry',
        [
            active => 0,

        ]
    ;
};

done_testing();