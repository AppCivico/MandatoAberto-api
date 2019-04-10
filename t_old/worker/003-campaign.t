use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    use_ok 'MandatoAberto::Worker::Campaign';

    my $worker = new_ok('MandatoAberto::Worker::Campaign', [ schema => $schema ]);
    ok( $worker->does('MandatoAberto::Worker'), 'worker does MandatoAberto::Worker' );

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );

    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my @recipient_ids = ();
    subtest 'Chatbot | Mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
            create_recipient(
                politician_id  => $politician_id,
                security_token => $security_token
            );

            my $recipient_id = stash 'recipient.id';
            push @recipient_ids, $recipient_id;
        }
    };

    subtest 'Politician | Create campaign' => sub {
        $politician->update( { premium => 1 } );

        my $dm = rest_post "/api/politician/$politician_id/direct-message",
            name                => "creating direct message",
            automatic_load_item => 0,
            stash               => 'dm1',
            [
                name    => 'foobar',
                content => 'foo',
            ]
        ;
        my $dm_id = $dm->{id};
        $dm       = $schema->resultset('DirectMessage')->find($dm_id);

        is( $dm->campaign->status_id, 1, 'message is processing' );
        is( $dm->campaign->count,     0, 'no recipients for now' );

        ok( $worker->run_once(), 'run once' );

        ok( $dm = $dm->discard_changes, 'discard changes' );
        is( $dm->campaign->status_id, 2, 'message has been sent' );
        is( $dm->campaign->count,     4, '4 recipients received it' );
    };
};

done_testing();

