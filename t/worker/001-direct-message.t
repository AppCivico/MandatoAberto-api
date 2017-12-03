use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    use_ok 'MandatoAberto::Worker::DirectMessage';
    use_ok 'MandatoAberto::Messager::Template';

    my $worker = new_ok('MandatoAberto::Worker::DirectMessage', [ schema => $schema ]);

    ok ($worker->does('MandatoAberto::Worker'), 'MandatoAberto::Worker::DirectMessage does MandatoAberto::DirectMessage');

    is ($schema->resultset('DirectMessageQueue')->count, "0", "there is no direct message queued yet");

    # Criando uma messagem.
    my $message = MandatoAberto::Messager::Template->new(
        to       => 'foobar',
        message  => 'foobar'
    )->build_message();

    ok(
        my $direct_message = $schema->resultset("DirectMessage")->create({
            politician_id => $politician_id,
            content       => $message,
        }),
        "message created",
    );

    ok (
        $schema->resultset("DirectMessageQueue")->create({
            direct_message_id => $direct_message->id,
        }),
        "message queued",
    );

    ok ($worker->run_once(), 'run once');

    is ($schema->resultset('DirectMessageQueue')->count, "0", "out of queue");
};

done_testing();

