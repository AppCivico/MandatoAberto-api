use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
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

    ok (
        $schema->resultset("DirectMessageQueue")->create({
            content => $message,
        }),
        "message queued",
    );

    ok ($worker->run_once(), 'run once');

    is ($schema->resultset('DirectMessageQueue')->count, "0", "out of queue");
};

done_testing();

