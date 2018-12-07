use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use DateTime;

my $schema = MandatoAberto->model("DB");

plan skip_all => "skip for now";


db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician    = $schema->resultset('Politician')->find(stash 'politician.id');
    my $politician_id = $politician->id;

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

    create_recipient(
        name          => 'foo',
        politician_id => $politician_id
    );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    subtest 'Chatbot | create logs' => sub {
        rest_post '/api/chatbot/log',
            name   => 'Create log (WENT_TO_FLOW)',
            code   => 200,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 1,
                payload         => 'greetings',
                human_name      => 'Voltar ao início'
            ]
        ;

        rest_post '/api/chatbot/log',
            name   => 'Create log (WENT_TO_FLOW)',
            code   => 200,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 1,
                payload         => 'aboutMe',
                human_name      => 'Saiba mais'
            ]
        ;
    };

    subtest 'Politician | list logs' => sub {
        api_auth_as user_id => $politician_id;

        rest_get "/api/politician/$politician_id/logs",
            name  => 'get logs',
            stash => 'get_logs',
            list  => 1
        ;

        stash_test 'get_logs' => sub {
            my $res = shift;

            is( ref $res->{logs},                         'ARRAY', 'logs is an array' );
            is( ref $res->{logs}->[0]->{created_at},      '',      'created_at is a string' );
            is( ref $res->{logs}->[0]->{description},     '',      'description is a string' );
            is( ref $res->{logs}->[0]->{recipient},       'HASH',  'recipient is a hash' );

            ok( defined $res->{itens_count},              'itens_count is defined' );
            ok( defined $res->{logs}->[0]->{created_at},  'created_at is defined' );
            ok( defined $res->{logs}->[0]->{description}, 'description is defined' );
        };

        my $second_recipient;
        subtest 'list logs with recipient_id' => sub {
            create_recipient(
                name          => 'bar',
                politician_id => $politician_id
            );
            $second_recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

            rest_post '/api/chatbot/log',
                name   => 'Create log (WENT_TO_FLOW)',
                code   => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $second_recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 1,
                    payload         => 'greetings',
                    human_name      => 'Voltar ao início'
                ]
            ;

            rest_get "/api/politician/$politician_id/logs",
                name  => 'get logs',
                stash => 'get_logs_filtered',
                list  => 1,
                [ recipient_id => $second_recipient->id ]
            ;

            stash_test 'get_logs_filtered' => sub {
                my $res = shift;

                is( scalar @{ $res->{logs} }, 1, 'only one log entry' );

                my $log = $res->{logs}->[0];

                is( $log->{description}, "bar acessou o fluxo 'Voltar ao início'.", 'expected description' );
            };
        };

        subtest 'list logs with action_id' => sub {
            rest_get "/api/politician/$politician_id/logs",
                name  => 'get logs',
                stash => 'get_logs_filtered',
                list  => 1,
                [ action_id => 1 ]
            ;

            stash_test 'get_logs_filtered' => sub {
                my $res = shift;

                is( scalar @{ $res->{logs} }, 3, '3 log entries' );
            };
        };

        subtest 'list logs with action_id and recipient_id' => sub {
            rest_get "/api/politician/$politician_id/logs",
                name  => 'get logs',
                stash => 'get_logs_filtered',
                list  => 1,
                [
                    action_id    => 1,
                    recipient_id => $second_recipient->id
                ]
            ;

            stash_test 'get_logs_filtered' => sub {
                my $res = shift;

                is( scalar @{ $res->{logs} }, 1, '1 log entry' );
            };

            rest_get "/api/politician/$politician_id/logs",
                name  => 'get logs',
                stash => 'get_logs_filtered',
                list  => 1,
                [
                    action_id    => 1,
                    recipient_id => $recipient->id
                ]
            ;

            stash_test 'get_logs_filtered' => sub {
                my $res = shift;

                is( scalar @{ $res->{logs} }, 2, '2 log entries' );
            };
        };
    };
};

done_testing();