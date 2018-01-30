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
                    citizen_id               => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 1 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Não'},
                }
            ),
        );

        # O recipient 1 escolheu 'Talvez' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[0],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Não'},
                }
            ),
        );

        # O recipient 3 escolheu 'Não' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[2],
                    poll_question_option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Não'},
                }
            ),
        );
    };

    api_auth_as user_id => $politician_id;

    use_ok 'MandatoAberto::Worker::Segmenter';
    my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

    subtest "filter 'QUESTION_ANSWER_EQUALS" => sub {

        # Neste filtro eu quero pegar quem respondeu 'Sim' para frango com catupiry e 'Talvez' para portuguesa.
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            stash   => 'group',
            automatic_load_item => 0,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_ANSWER_NOT_EQUALS" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            stash   => 'group',
            automatic_load_item => 0,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_IS_NOT_ANSWERED" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            stash   => 'group',
            automatic_load_item => 0,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                name     => 'AppCivico',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => { field => $poll_questions[2]->id },
                        },
                    ],
                },
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        is_deeply(
            [ sort $recipient_ids[2], $recipient_ids[3] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
        );
    };

    subtest "filter 'QUESTION_IS_ANSWERED" => sub {

        # Neste filtro eu quero pegar quem respondeu algo diferente de 'Talvez' e diferente de 'Sim' para 4 quejos.
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            stash   => 'group',
            automatic_load_item => 0,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
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
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        is_deeply(
            [ sort $recipient_ids[0], $recipient_ids[1] ],
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_id($group_id)->all ],
        );
    };

    subtest 'count filter' => sub {

        rest_post "/api/politician/$politician_id/group/count",
            name    => 'count filter',
            stash   => 'count_filter',
            code    => 200,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => { field => $poll_questions[2]->id },
                        },
                    ],
                },
            }),
        ;

        stash_test 'count_filter' => sub {
            my $res = shift;

            is( $res->{count}, '2', 'count=2' );
        };
    };
};


done_testing();

