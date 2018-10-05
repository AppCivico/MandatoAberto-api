use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;
use Mojo::JSON qw(encode_json decode_json);

my $t = test_instance;
my $schema = $t->app->schema;

use_ok 'MandatoAberto::Worker::Segmenter';

my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

db_transaction {
    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    my $politician = create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = $politician->{id};

    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
            my $recipient_id = create_recipient(
                politician_id  => $politician_id,
                security_token => $security_token
            );
            push @recipient_ids, $recipient_id;
        }
    };

    my $poll;
    subtest 'mocking poll' => sub {
        ok(
            $poll = $schema->resultset('Poll')->create(
                {
                    name          => 'Pizza',
                    politician_id => $politician_id,
                    status_id     => 1,
                },
            ),
            'add poll',
        );
    };

    my @poll_questions = ();
    subtest 'mocking questions' => sub {

        my @questions = (
            'Você gosta de frango com catupiry?',
            'Você gosta de quatro queijos?',
            'Você gosta de portuguesa?',
        );

        for my $content (@questions) {
            ok(
                my $poll_question = $schema->resultset('PollQuestion')->create(
                    {
                        poll_id => $poll->id,
                        content => $content,
                    },
                ),
                'add poll question',
            );

            push @poll_questions, $poll_question;
        }
    };

    my %text_to_options_id = ();
    subtest 'mocking questions' => sub {

        for my $poll_question (@poll_questions) {
            for my $content (qw/ Sim Não Talvez /) {
                my $poll_question_id = $poll_question->id;

                ok(
                    my $poll_question_option = $schema->resultset('PollQuestionOption')->create(
                        {
                            poll_question_id => $poll_question_id,
                            content          => $content,
                        },
                    ),
                    'add question option',
                );

                $text_to_options_id{$poll_question_id}->{$content} = $poll_question_option->id;
            }
        }
    };

    subtest 'mocking results' => sub {

        # O recipient 1 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[0],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 1 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[0],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[1]->id }->{'Não'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 1 escolheu 'Talvez' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[0],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[2]->id }->{'Talvez'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 2 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[1],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[1],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[1]->id }->{'Talvez'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[1],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[2]->id }->{'Não'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );

        # O recipient 3 escolheu 'Não' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id            => $recipient_ids[2],
                    poll_question_option_id => $text_to_options_id{ $poll_questions[0]->id }->{'Não'},
                    origin                  => fake_pick( qw/ dialog propagate / )->()
                }
            ),
        );
    };

    api_auth_as user_id => $politician_id;

    subtest "filter 'QUESTION_ANSWER_EQUALS" => sub {

        # Neste filtro eu quero pegar quem respondeu 'Sim' para frango com catupiry e 'Talvez' para portuguesa.
        #rest_post "/api/politician/$politician_id/group",
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules => [
                        {
                            name => 'QUESTION_ANSWER_EQUALS',
                            data => {
                                field => $poll_questions[0]->id,
                                value => 'Sim',
                            },
                        },
                        {
                            name => 'QUESTION_ANSWER_EQUALS',
                            data => {
                                field => $poll_questions[2]->id,
                                value => 'Talvez',
                            },
                        },
                    ],
                },
            },
        )
        ->status_is(201);

        my $group_id = $t->tx->res->json->{id};

        ok( $worker->run_once(), 'run once' );

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_ANSWER_NOT_EQUALS" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules => [
                        {
                            name => 'QUESTION_ANSWER_NOT_EQUALS',
                            data => {
                                field => $poll_questions[1]->id,
                                value => 'Sim',
                            },
                        },
                        {
                            name => 'QUESTION_ANSWER_NOT_EQUALS',
                            data => {
                                field => $poll_questions[1]->id,
                                value => 'Talvez',
                            },
                        },
                    ],
                },
            },
        )
        ->status_is(201);

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_IS_NOT_ANSWERED" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name   => 'AppCivico',
                filter => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => { field => $poll_questions[2]->id },
                        },
                    ],
                },
            },
        )
        ->status_is(201);

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};

        is_deeply(
            [ sort $recipient_ids[2], $recipient_ids[3] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_IS_ANSWERED" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'Question Is Answered',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'QUESTION_IS_ANSWERED',
                            data => { field => $poll_questions[2]->id },
                        },
                    ],
                },
            },
        )
        ->status_is(201);

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest 'count filter' => sub {

        $t->post_ok(
            "/api/politician/$politician_id/group/count",
            headers => [ 'Content-Type' => 'application/json' ],
            json    => {
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => { field => $poll_questions[2]->id },
                        },
                    ],
                },
            }
        )
        ->status_is(201)
        ->json_is('/count', 2, 'count=2');
    };
};

db_transaction {
    api_auth_as user_id => 1;

    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    my $politician = create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = $politician->{id};

    api_auth_as user_id => $politician_id;

    my $first_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );

    my $second_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'M'
    );

    my $third_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );

    # Esses filtros selecionam os recipients por gênero
    db_transaction {
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'Gender',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'GENDER_IS',
                            data => { value => 'F' },
                        },
                    ],
                },
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};
        ok my $group = $schema->resultset("Group")->find($group_id), 'get group';
        is $group->discard_changes->recipients_count, 2, 'recipient count';
    };

    db_transaction {
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'Gender',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'GENDER_IS_NOT',
                            data => { value => 'F' },
                        },
                    ],
                },
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};
        ok my $group = $schema->resultset("Group")->find($group_id), 'get group';

        is $group->discard_changes->recipients_count, 1, 'recipient count';
    };

};

db_transaction {
    api_auth_as user_id => 1;

    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = $t->tx->res->json->{id};

    api_auth_as user_id => $politician_id;

    my $first_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $first_recipient    = $schema->resultset('Recipient')->find($first_recipient_id);

    my $second_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'M'
    );

    my $third_recipient_id = create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );

    $t->post_ok(
        "/api/chatbot/issue",
        form => {
            politician_id  => $politician_id,
            fb_id          => $first_recipient->fb_id,
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
        }
    )
    ->status_is(201);

    ok my $entity = $schema->resultset('PoliticianEntity')->search(
        {
            politician_id => $politician_id,
            name          => 'direitos_animais'
        }
    )->next;

    # Esses filtros selecionam os recipients por gênero
    db_transaction {
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'Gender',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'INTENT_IS',
                            data => { value => $entity->id },
                        },
                    ],
                },
            }
        )
        ->status_is(201);

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 1, 'recipient count');
    };

    db_transaction {
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'Gender',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'INTENT_IS_NOT',
                            data => { value => $entity->id },
                        },
                    ],
                },
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        ok my $group_id = $t->tx->res->json->{id};

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 2, 'recipient count');
    };

};

done_testing();