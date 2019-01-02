use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        fb_page_id => 'foo',
    );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    subtest 'Chatbot | Create invalid recipient' => sub {
        # Create recipient without fb_id
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                politician_id  => $politician_id,
                origin_dialog  => fake_words(1)->(),
                name           => fake_name()->(),
                security_token => $security_token
            }
        )
        ->status_is(400);

        # Create recipient without name
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                politician_id  => $politician_id,
                origin_dialog  => fake_words(1)->(),
                security_token => $security_token,
                fb_id          => "foobar",
            }
        )
        ->status_is(400);

        # Email is not required but must be valid
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                origin_dialog => fake_words(1)->(),
                name          => fake_name()->(),
                politician_id => $politician_id,
                fb_id         => "foobar",
                email         => "foobar",
                security_token => $security_token
            }
        )
        ->status_is(400);

        # Cellphone is not required but must be valid
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                origin_dialog => fake_words(1)->(),
                name          => fake_name()->(),
                politician_id => $politician_id,
                fb_id         => "foobar",
                cellphone     => "foobar",
                security_token => $security_token
            }
        )
        ->status_is(400);

        # Gender is not required but must be valid
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                origin_dialog => fake_words(1)->(),
                name          => fake_name()->(),
                politician_id => $politician_id,
                fb_id         => "foobar",
                gender        => "foobar",
                security_token => $security_token
            }
        )
        ->status_is(400);
    };

    my $fb_id     = fake_words(1)->();
    my $cellphone = fake_digits("+551198#######")->();
    my $email     = fake_email()->();
    my $gender    = fake_pick( qw/F M/ )->();

    my $recipient_id;

    subtest 'Chatbot | Create recipient' => sub {
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                origin_dialog => fake_words(1)->(),
                politician_id => $politician_id,
                name          => fake_name()->(),
                fb_id         => $fb_id,
                email         => $email,
                cellphone     => $cellphone,
                gender        => $gender,
                security_token => $security_token
            }
        )
        ->status_is(201)
        ->json_has('/id');

        $recipient_id = $t->tx->res->json->{id};
    };

    subtest 'Chatbot | GET recipient' => sub {
        # Search with missing fb_id
        $t->get_ok(
            '/api/chatbot/recipient',
            form => { security_token => $security_token }
        )
        ->status_is(400);


        $t->get_ok(
            '/api/chatbot/recipient',
            form => {
                security_token => $security_token,
                fb_id          => $fb_id,
            }
        )
        ->status_is(200)
        ->json_has('/id')
        ->json_has('/email')
        ->json_has('/cellphone')
        ->json_has('/gender')
        ->json_has('/poll_notification_sent')
        ->json_is('/id',        $recipient_id,  'recipient id')
        ->json_is('/email',     $email,         'recipient email')
        ->json_is('/cellphone', $cellphone,     'recipient cellphone')
        ->json_is('/gender',    $gender,        'recipient gender')
        ->json_is('/poll_notification_sent', 0, 'poll notification not sent');
    };

    my $new_email = fake_email()->();

    subtest 'Chatbot | Update recipient data' => sub {
        # Search with missing fb_id
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
                fb_id          => $fb_id,
                politician_id  => $politician_id,
                email          => $new_email,
                security_token => $security_token
            }
        )
        ->status_is(201);

        $t->get_ok(
            '/api/chatbot/recipient',
            form => {
                security_token => $security_token,
                fb_id          => $fb_id,
            }
        )
        ->status_is(200)
        ->json_is('/id',        $recipient_id,  'recipient id')
        ->json_is('/email',     $new_email,     'recipient updated email');
    };
};

done_testing();
