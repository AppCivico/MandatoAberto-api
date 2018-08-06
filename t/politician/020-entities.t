use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician    = $schema->resultset('Politician')->find(stash 'politician.id');
    my $politician_id = $politician->id;

    create_recipient( politician_id => $politician_id );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    # Criando a entidade
    my $entity = $schema->resultset('Entity')->create( { name => 'Saúde' } );
    my $sub_entity = $schema->resultset('SubEntity')->create( { name => 'Posto de Saúde', entity_id => $entity->id } );

    my $politician_entity = $schema->resultset('PoliticianEntity')->create(
        {
            politician_id   => $politician_id,
            entity_id       => $entity->id,
            sub_entity_id   => $sub_entity->id,
            recipient_count => 1,
        }
    );
    my $politician_entity_id = $politician_entity->id;

    $recipient->update( { entities => [$politician_entity_id] } );

    api_auth_as user_id => $politician_id;

    rest_get "/api/politician/$politician_id/intent",
        name  => 'get entities',
        stash => 'get_entities',
        list  => 1
    ;

    stash_test 'get_entities' => sub {
        my $res = shift;

        is ( ref $res->{politician_entities}, 'ARRAY', 'expected array' );
        ok ( my $politician_entity_res = $res->{politician_entities}->[0], 'politician entity' );
        is ( ref $res->{politician_entities}, 'ARRAY', 'expected array' );

    }

};

done_testing();