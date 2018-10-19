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

    my ( $recipient, $entity );
    subtest 'Chatbot | Create recipient and issue' => sub {

        $recipient = create_recipient( politician_id => $politician_id );
        $recipient = $schema->resultset('Recipient')->find( $recipient->{id} );

        # Criando issue para criar um tema
        create_issue(
            fb_id         => $recipient->fb_id,
            politician_id => $politician->id
        );

        my $entity_rs = $schema->resultset('PoliticianEntity');
        $entity       = $entity_rs->search( { politician_id => $politician_id } )->next;

        is ( $entity_rs->count, 1, 'one entity created' );
    };

    subtest 'Chatbot | Create entity stats' => sub {
        my $entity_id    = $entity->id;
        my $recipient_id = $recipient->id;

        rest_post "/api/chatbot/politician/$politician_id/intents/$entity_id/stats",
            name                => 'Create entity stats',
            automatic_load_item => 0,
            stash               => 's1',
            [
                entity_is_correct => 1,
                security_token    => $security_token,
                recipient_id      => $recipient_id
            ]
        ;

        is( $entity->recipient_count, 1, 'one recipient' );
    };
};

done_testing();