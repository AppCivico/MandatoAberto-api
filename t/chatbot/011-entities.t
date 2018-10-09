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

    # Criando issue para criar um tema
    create_issue(
        fb_id         => $recipient->fb_id,
        politician_id => $politician->id
    );

    my $entity_rs = $schema->resultset('PoliticianEntity');
    my $entity = $entity_rs->search( { politician_id => $politician_id } )->next;

    is ( $entity_rs->count, 1, 'one entity created' );

    # Esse tema não deve aparecer nos temas disponíveis
    rest_get '/api/chatbot/intents/available',
        name  => 'get available intents',
        stash => 'get_available_intents',
        list  => 1,
        [
            security_token => $security_token,
            fb_page_id     => $politician->fb_page_id
        ]
    ;

    stash_test 'get_available_intents' => sub {
        my $res = shift;

        is( scalar @{ $res->{intents} }, 0, 'no available intents' );
    };

    api_auth_as user_id => $politician_id;
    create_knowledge_base(
        politician_id => $politician_id,
        entity_id     => $entity->id
    );

    rest_reload_list 'get_available_intents';
    stash_test 'get_available_intents.list' => sub {
        my $res = shift;

        is( scalar @{ $res->{intents} }, 1, '1 available intent' );
    };
};

done_testing();