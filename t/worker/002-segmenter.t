use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use MandatoAberto::Utils;

my $schema = MandatoAberto->model('DB');

db_transaction {
    use_ok 'MandatoAberto::Worker::Segmenter';

    my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);
    ok( $worker->does('MandatoAberto::Worker'), 'worker does MandatoAberto::Worker' );

    create_politician;
    my $politician_id = stash "politician.id";
    api_auth_as user_id => $politician_id;

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

    my $group_id = stash 'group.id';
    my $group = $schema->resultset('Group')->search( { 'me.id' => $group_id } )->next;

    is( $group->recipients_count,        undef, 'recipients_count=undef' );
    is( $group->last_recipients_calc_at, undef, 'last_recipients_calc_at=undef' );
    is( $group->status,                  'processing', 'status=processing' );

    my $recipients_rs = $schema->resultset('Recipient')->search_by_group_id($group_id);

    is( $recipients_rs->count, '0', 'count=0' );

    ok( $worker->run_once(), 'run once' );

    ok( $group->discard_changes,  'discard_changes' );
    is( $group->status,           'ready', 'status=ready' );
    is( $group->recipients_count, $recipients_rs->count, 'recipients_count=2' );
    isnt( $group->last_recipients_calc_at, undef, 'last_recipients_calc_at is not undef' );

    ok( !$worker->run_once(), 'no groups remaining' );
};

done_testing();

