use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
            create_recipient(politician_id => $politician_id);

            my $recipient_id = stash 'recipient.id';
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
                    recipient_id             => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 1 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id  => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Não'},
                }
            ),
        );

        # O recipient 1 escolheu 'Talvez' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Não'},
                }
            ),
        );

        # O recipient 3 escolheu 'Não' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    recipient_id => $recipient_ids[2],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Não'},
                }
            ),
        );
    };

    api_auth_as user_id => $politician_id;

    subtest 'validate operators' => sub {

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            is_fail => 1,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                name     => 'AppCivico',
                filter   => {
                    operator => 'NOT_EXISTS',
                    rules    => [],
                },
            }),
        ;

        my $rules = [
            {
                name => 'QUESTION_ANSWER_EQUALS',
                data => {
                    field => '32',
                    value => 'Sim',
                },
            },
        ];

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                name     => 'AppCivico',
                filter   => {
                    operator => 'AND',
                    rules => $rules,
                },
            }),
        ;

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                name     => 'AppCivico',
                filter   => {
                    operator => 'OR',
                    rules    => $rules,
                },
            }),
        ;
    };

    subtest 'validate rules' => sub {

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group with invalid filter',
            is_fail => 1,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;
    };

    subtest 'validate data keys' => sub {

        rest_post "/api/politician/$politician_id/group",
            name    => 'add group with invalid data key',
            is_fail => 1,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;
    };

    subtest 'list created groups' => sub {

        rest_get "/api/politician/$politician_id/group", name => 'list groups', stash => 'groups';

        stash_test 'groups' => sub {
            my $res = shift;

            for my $group (@{ $res->{groups} }) {
                is( $group->{name}, 'AppCivico', 'name=AppCivico' );
                is( ref($group->{filter}),          'HASH',  'filters=HASH' );
                is( ref($group->{filter}->{rules}), 'ARRAY', 'rules=HASH' );
            }
        };
    };

    use_ok 'MandatoAberto::Worker::Segmenter';
    my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

    my $group_id;
    subtest 'edit group' => sub {

        $group_id = (stash 'groups')->{groups}->[0]->{id};

        ok(
            $schema->resultset('Group')->search( { id => { '!=', $group_id } } )->delete,
            'delete other groups to run worker once'
        );
        ok( $worker->run_once(), 'run once' );

        rest_put "/api/politician/$politician_id/group/$group_id",
            name    => 'edit group',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        rest_get "/api/politician/$politician_id/group/$group_id", name => 'get group', stash => 'group';

        stash_test 'group' => sub {
            my $res = shift;

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

        rest_put "/api/politician/$politician_id/group/$group_id",
            name    => 'edit group again',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        # Atualmente o estado desse grupo é 'processing'. Não devemos poder editá-lo novamente enquanto não
        # estiver 'ready'.
        rest_put "/api/politician/$politician_id/group/$group_id",
            name    => 'edit group again',
            is_fail => 1,
            code    => 400,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;
    };

    subtest 'delete group' => sub {

        rest_delete "/api/politician/$politician_id/group/$group_id", name => 'delete group';

        rest_get "/api/politician/$politician_id/group/$group_id",
            name    => 'get deleted group',
            is_fail => 1,
            code    => 404,
        ;
    };
};

done_testing();

