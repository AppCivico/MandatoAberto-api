use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    use_ok 'MandatoAberto::Worker::PollNotification';

    my $worker = new_ok('MandatoAberto::Worker::PollNotification', [ schema => $schema ]);
    ok( $worker->does('MandatoAberto::Worker'), 'worker does MandatoAberto::Worker' );

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician(fb_page_id => fake_words(1)->());
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    $politician->user->organization_chatbot->poll_self_propagation_config->update( { active => 1 } );


    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

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

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => 'foobar',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
        ]
    ;
    my $poll_id = stash "p1.id";
    my $poll    = $schema->resultset('Poll')->find($poll_id);

    my $poll_self_propagation_queue_rs = $schema->resultset('PollSelfPropagationQueue');
    is ( $poll_self_propagation_queue_rs->count, 4, '4 on queue' );

    ok ($worker->run_once(), 'run once');

    is ($poll_self_propagation_queue_rs->count, "3", "1 out of queue");
};

done_testing();

