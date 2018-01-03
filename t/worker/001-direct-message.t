use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    create_politician( fb_page_access_token => "aaaaa" );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name                => "create citizen",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => fake_words(1)->(),
            email         => fake_email()->(),
            cellphone     => fake_digits("+551198#######")->(),
            gender        => fake_pick( qw/F M/ )->()
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name                => "create citizen",
        automatic_load_item => 0,
        stash               => 'c2',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => fake_words(1)->(),
            email         => fake_email()->(),
            cellphone     => fake_digits("+551198#######")->(),
            gender        => fake_pick( qw/F M/ )->()
        ]
    ;

    use_ok 'MandatoAberto::Worker::DirectMessage';
    use_ok 'MandatoAberto::Messager::Template';

    my $worker = new_ok( 'MandatoAberto::Worker::DirectMessage', [ schema => $schema ] );

    ok( $worker->does('MandatoAberto::Worker'),
        'MandatoAberto::Worker::DirectMessage does MandatoAberto::DirectMessage' );

    is( $schema->resultset('DirectMessageQueue')->count, "0", "there is no direct message queued yet" );

    # Criando uma messagem.
    my $message = MandatoAberto::Messager::Template->new(
        to      => 'foobar',
        message => 'foobar'
    )->build_message();

    ok(
        my $direct_message = $schema->resultset("DirectMessage")->create(
            {
                politician_id => $politician_id,
                content       => $message,
                name          => 'Mensagem Bacana',
            }
        ),
        "message created",
    );

    ok(
        $schema->resultset("DirectMessageQueue")->create(
            {
                direct_message_id => $direct_message->id,
            }
        ),
        "message queued",
    );

    ok( $worker->run_once(), 'run once' );

    is( $schema->resultset('DirectMessageQueue')->count, "0", "out of queue" );
};

done_testing();
