use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    my $politician = create_politician(fb_page_id => 'foo');
    my $politician_id = $politician->{id};

    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
           ok my $recipient_id = create_recipient(
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

    subtest 'validate operators' => sub {

        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'NOT_EXISTS',
                    rules    => [],
                },
            }
        )
        ->status_is(400)
        ->json_is('/error',             'form_error')
        ->json_is('/form_error/filter', 'invalid');

        my $rules = [
            {
                name => 'QUESTION_ANSWER_EQUALS',
                data => {
                    field => '32',
                    value => 'Sim',
                },
            },
        ];

        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'AND',
                    rules => $rules,
                },
            }
        )
        ->status_is(201)
        ->json_has('/id');

        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules => $rules,
                },
            }
        )
        ->status_is(201)
        ->json_has('/id');
    };

    subtest 'validate rules' => sub {

        # add group with invalid filter
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'RULE_THAT_NOT_EXISTS',
                            data => {
                                field => '32',
                                value => 'Sim',
                            },
                        },
                    ],
                },
            }
        )
        ->status_is(400)
        ->json_is('/error',             'form_error')
        ->json_is('/form_error/filter', 'invalid');

         $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'QUESTION_ANSWER_EQUALS',
                            data => {
                                field => '32',
                                value => 'Sim',
                            },
                        },
                    ],
                },
            }
        )
        ->status_is(201)
        ->json_has('/id');

    };

    subtest 'validate data keys' => sub {

        # add group with invalid data key
        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules    => [
                        {
                            name => 'QUESTION_ANSWER_EQUALS',
                            data => {
                                foo   => 'bar',
                                value => 'Não',
                            },
                        },
                    ],
                },
            }
        )
        ->status_is(400)
        ->json_is('/error',             'form_error')
        ->json_is('/form_error/filter', 'invalid');

    };

    subtest 'empty rules is not allowed' => sub {

        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules    => [],
                },
            }
        )
        ->status_is(400)
        ->json_is('/error',             'form_error')
        ->json_is('/form_error/filter', 'invalid');

    };

    db_transaction {
        # grupo sem filtro é permitido

        $t->post_ok(
            "/api/politician/$politician_id/group",
            json => {
                name     => 'AppCivico',
                filter   => {},
            }
        )
        ->status_is(201)
        ->json_has('/id');

    };

    my $res;
    subtest 'list created groups' => sub {

        $t->get_ok(
            "/api/politician/$politician_id/group"
        )
        ->status_is(200);

        $res = $t->tx->res->json;

        for my $group (@{ $res->{groups} }) {
            is( $group->{name}, 'AppCivico', 'name=AppCivico' );
            is( ref($group->{filter}),          'HASH',  'filters=HASH' );
            is( ref($group->{filter}->{rules}), 'ARRAY', 'rules=HASH' );
        }
    };

    use_ok 'MandatoAberto::Worker::Segmenter';
    my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

    my $group_id;
    subtest 'edit group' => sub {

        $group_id = $res->{groups}->[0]->{id};

        ok(
            $schema->resultset('Group')->search( { id => { '!=', $group_id } } )->delete,
            'delete other groups to run worker once'
        );
        ok( $worker->run_once(), 'run once' );

        $t->put_ok(
            "/api/politician/$politician_id/group/$group_id",
            json => {
                name     => 'Edited',
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => {
                                field => $poll_questions[-1]->id,
                            },
                        },
                    ],
                },
            }
        )
        ->status_is(202)
        ->json_has('/id');

        ok( $worker->run_once(), 'run once' );

        $t->get_ok("/api/politician/$politician_id/group/$group_id")->status_is(200);
        $res = $t->tx->res->json;

        subtest 'test get' => sub {
            is(   ref($res->{filter}),          'HASH',  'filter=hashref' );
            is(   ref($res->{filter}->{rules}), 'ARRAY', 'rules=arrayref' );
            isnt( $res->{updated_at},           undef,   'updated_at filled' );

            is( $res->{name}, 'Edited', 'name=Edited' );
            is( $res->{filter}->{rules}->[0]->{name}, 'QUESTION_IS_NOT_ANSWERED', 'rule_name=QUESTION_IS_NOT_ANSWERED' );
            is( $res->{filter}->{rules}->[0]->{data}->{field}, $poll_questions[-1]->id, 'rule_data_field' );
            is( $res->{filter}->{rules}->[0]->{data}->{value}, undef, 'rule_data_value=undef' );

            is( ref($res->{recipients}), 'ARRAY', 'recipients=arrayref' );

            # Somente os dois ultimos recipients não responderam a última questão.
            is_deeply(
                [ sort $recipient_ids[2], $recipient_ids[3] ],
                [ sort map { $_->{id} } @{ $res->{recipients} } ],
            );
        };
    };

    subtest 'edit locked group' => sub {

        $t->put_ok(
            "/api/politician/$politician_id/group/$group_id",
            json => {
                name     => 'Edited',
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'QUESTION_IS_ANSWERED',
                            data => {
                                field => $poll_questions[-1]->id,
                            },
                        },
                    ],
                },
            }
        )
        ->status_is(202);

        # Atualmente o estado desse grupo é 'processing'. Não devemos poder editá-lo novamente enquanto não
        # estiver 'ready'.
		$t->put_ok(
			"/api/politician/$politician_id/group/$group_id",
			json => {
                name     => 'Edited',
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => {
                                field => $poll_questions[-1]->id,
                            },
                        },
                    ],
                },
			}
		)
        ->status_is(400)
        ;
    };

    subtest 'delete group' => sub {

        $t->delete_ok( "/api/politician/$politician_id/group/$group_id" );
        $t->get_ok(
            "/api/politician/$politician_id/group/$group_id"
        )
        ->status_is(404);
    };

    subtest 'paginate groups' => sub {

        # Criando 25 grupos.
        for my $i ( 1 .. 25 ) {
            $t->post_ok(
                "/api/politician/$politician_id/group",
                json => {
                    name     => "AppCivico $i",
                    filter   => {
                        operator => fake_pick(qw/ AND OR /)->(),
                        rules    => [
                            {
                                name => 'QUESTION_ANSWER_EQUALS',
                                data => {
                                    field => fake_int(1, 99)->(),
                                    value => fake_pick(qw/ Sim Não Talvez /)->(),
                                },
                            },
                        ],
                    },
                }
            )
            ->status_is(201)
            ->json_has('/id');
        }

        $t->get_ok("/api/politician/$politician_id/group")->status_is(200);

        $res = $t->tx->res->json;

        # O default é 20 itens sem parâmetros 'page' e 'results'.
        is( scalar(@{ $res->{groups} }), 20, 'count=20' );

		$t->get_ok("/api/politician/$politician_id/group?results=3&page=2")->status_is(200);
		$res = $t->tx->res->json;

        is( scalar(@{ $res->{groups} }), 3, 'count=3' );
        is( $res->{total}, 25, 'total=25' );
        is_deeply(
            [ sort map { $_->{name} } @{ $res->{groups } } ],
            [ 'AppCivico 4', 'AppCivico 5', 'AppCivico 6' ],
        );

    };
};

done_testing();

