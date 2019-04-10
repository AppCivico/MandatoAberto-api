use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    use_ok 'MandatoAberto::Worker::Email';
    use_ok 'MandatoAberto::Mailer::Template';

    my $worker = new_ok('MandatoAberto::Worker::Email', [ schema => $schema ]);

    ok ($worker->does('MandatoAberto::Worker'), 'MandatoAberto::Worker::Email does MandatoAberto::Worker');

    is ($schema->resultset('EmailQueue')->count, "0", "there is no email queued yet");

    # Criando um email.
    my $email = MandatoAberto::Mailer::Template->new(
        to       => fake_email()->(),
        from     => fake_email()->(),
        subject  => fake_sentences(1)->(),
        template => fake_paragraphs(3)->(),
        vars     => {},
    )->build_email();

    isa_ok ($email, "MIME::Lite", "built mail");

    ok (
        $schema->resultset("EmailQueue")->create({
            body => $email->as_string,
        }),
        "email queued",
    );

    ok ($worker->run_once(), 'run once');

    is ($schema->resultset('EmailQueue')->count, "0", "out of queue");
};

done_testing();

