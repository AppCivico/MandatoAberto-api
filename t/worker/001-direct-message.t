use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    use_ok 'MandatoAberto::Worker::DirectMessage';

    my $worker = new_ok('MandatoAberto::Worker::DirectMessage', [ schema => $schema ]);

    ok ($worker->does('MandatoAberto::Worker'), 'MandatoAberto::Worker::DirectMessage does MandatoAberto::DirectMessage');

    is ($schema->resultset('DirectMessage')->count, "0", "there is no direct message queued yet");

    # Criando um email.
    my $message = MandatoAberto::Messager::Template->new(
        to       => 'foobar',
        message  => 'foobar'
    )->build_message();

    ok (
        $schema->resultset("DirectMessage")->create({
            content => $message->as_string,
        }),
        "message queued",
    );

    ok ($worker->run_once(), 'run once');

    is ($schema->resultset('DirectMessage')->count, "0", "out of queue");
};

done_testing();

