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

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    create_recipient( politician_id => $politician_id );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    subtest 'Chatbot | get actions' => sub {
        rest_get '/api/chatbot/log/actions',
            name   => 'Get actions',
            stash  => 'get_actions',
            code   => 200,
            [ security_token => $security_token ]
        ;

        stash_test 'get_actions' => sub {
            my $res = shift;

            is( ref $res->{actions},                  'ARRAY', 'actions is an array' );
            ok( defined $res->{actions}->[0]->{id},   'id is defined' );
            ok( defined $res->{actions}->[0]->{name}, 'name is defined' );
        };
    };

    subtest 'Chatbot | Create log flow change' => sub {
        rest_post '/api/chatbot/log',
            name    => 'Create log without payload',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 1,
                human_name      => 'Voltar ao início'
            ]
        ;

        rest_post '/api/chatbot/log',
            name    => 'Create log without human_name',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 1,
                payload         => 'greetings',
            ]
        ;

        rest_post '/api/chatbot/log',
            name    => 'Create log without action_id',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                payload         => 'greetings',
                human_name      => 'Voltar ao início'
            ]
        ;

        rest_post '/api/chatbot/log',
            name    => 'Create log without timestamp',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 1,
                payload         => 'greetings',
                human_name      => 'Voltar ao início'
            ]
        ;

        rest_post '/api/chatbot/log',
            name    => 'Create log without recipient_fb_id',
            is_fail => 1,
            code    => 400,
            [
                timestamp       => DateTime->now->stringify,
                security_token  => $security_token,
                politician_id   => $politician_id,
                action_id       => 1,
                payload         => 'greetings',
                human_name      => 'Voltar ao início'
            ]
        ;

        db_transaction {
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

            is( $schema->resultset('ChatbotStep')->count, 1, 'one ChatbotStep' );
            is( $schema->resultset('Log')->count,         1, 'one Log' );

            rest_post '/api/chatbot/log',
                name    => 'Create log with duplicate human_name',
                is_fail => 1,
                code    => 400,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 1,
                    payload         => 'foobar',
                    human_name      => 'Voltar ao início'
                ]
            ;

            rest_post '/api/chatbot/log',
                name   => 'Updating step',
                code   => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 1,
                    payload         => 'greetings',
                    human_name      => 'foobar'
                ]
            ;

            is( $schema->resultset('ChatbotStep')->count, 1, 'one ChatbotStep' );
            is( $schema->resultset('Log')->count,         2, 'two Log entries' );

        };
    };

    subtest 'Chatbot | Create log answered poll' => sub {
        # Mocking poll
        ok(
            my $poll = $schema->resultset('Poll')->create(
                {
                    name                    => 'foobar',
                    organization_chatbot_id => $organization_chatbot_id,
                    status_id               => 1,
                },
            ),
            'add poll',
        );

        ok(
            my $poll_question = $schema->resultset('PollQuestion')->create(
                {
                    poll_id => $poll->id,
                    content => 'foo',
                },
            ),
            'add poll question',
        );

        ok(
            my $poll_question_option = $schema->resultset('PollQuestionOption')->create(
                {
                    poll_question_id => $poll_question->id,
                    content          => 'bar',
                },
            ),
            'add question option',
        );

        rest_post '/api/chatbot/log',
            name    => 'Create log without field_id',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                politician_id   => $politician_id,
                recipient_fb_id => $recipient->fb_id,
                action_id       => 2,
            ]
        ;

        rest_post '/api/chatbot/log',
            name    => 'Create log with inexistent field_id',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                politician_id   => $politician_id,
                recipient_fb_id => $recipient->fb_id,
                action_id       => 2,
                field_id        => 9999999,
            ]
        ;

        db_transaction{
            rest_post '/api/chatbot/log',
                name => 'Create log (ANSWERED_POLL)',
                code => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    politician_id   => $politician_id,
                    recipient_fb_id => $recipient->fb_id,
                    action_id       => 2,
                    field_id        => $poll_question_option->id,
                ]
            ;

            is( $schema->resultset('Log')->count, 1, 'one Log' );
        };
    };

    subtest 'Chatbot | Create log notifications' => sub {
        rest_post '/api/chatbot/log',
            name    => 'Create log with field_id',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 3,
                field_id        => 1,
            ]
        ;

        db_transaction{
            rest_post '/api/chatbot/log',
                name => 'Create log (ACTIVATED_NOTIFICATIONS)',
                code => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 3,
                ]
            ;

            rest_post '/api/chatbot/log',
                name => 'Create log (DEACTIVATED_NOTIFICATIONS)',
                code => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 4,
                ]
            ;

            is( $schema->resultset('Log')->count, 2, 'two Log entries' );
        }
    };

    subtest 'Chatbot | Create log asked about entity' => sub {
        # Creating entity
        rest_post "/api/chatbot/issue",
            name                => "issue creation",
            automatic_load_item => 0,
            stash               => "i1",
            [
                politician_id  => $politician_id,
                fb_id          => $recipient->fb_id,
                message        => fake_words(1)->(),
                security_token => $security_token,
                entities       => encode_json(
                    {
                        id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
                        timestamp => '2018-09-19T21 => 39 => 43.452Z',
                        lang      => 'pt-br',
                        result    => {
                            source           => 'agent',
                            resolvedQuery    => 'O que você acha do aborto?',
                            action           => '',
                            actionIncomplete => 0,
                            parameters       => {},
                            contexts         => [],
                            metadata         => {
                                intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
                                webhookUsed               => 0,
                                webhookForSlotFillingUsed => 0,
                                isFallbackIntent          => 0,
                                intentName                => 'direitos_animais'
                            },
                            fulfillment => { speech =>  '', messages =>  [] },
                            score       => 1
                        },
                        status    => { code =>  200, errorType =>  'success' },
                        sessionId => '1938538852857638'
                    }
                )
            ],
        ;

        ok ( my $entity = $politician->user->organization_chatbot->politician_entities->search(undef)->next, 'entity' );

        rest_post '/api/chatbot/log',
            name    => 'Create log with invalid field_id',
            is_fail => 1,
            code    => 400,
            [
                security_token  => $security_token,
                timestamp       => DateTime->now->stringify,
                recipient_fb_id => $recipient->fb_id,
                politician_id   => $politician_id,
                action_id       => 5,
                field_id        => 9999999,
            ]
        ;

        db_transaction{
            rest_post '/api/chatbot/log',
                name => 'Create log (ASKED_ABOUT_ENTITY)',
                code => 200,
                [
                    security_token  => $security_token,
                    timestamp       => DateTime->now->stringify,
                    recipient_fb_id => $recipient->fb_id,
                    politician_id   => $politician_id,
                    action_id       => 5,
                    field_id        => $entity->id
                ]
            ;

            is( $schema->resultset('Log')->count, 1, 'one Log entry' );
        }
    };
};

done_testing();
