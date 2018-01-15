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
            rest_post '/api/chatbot/citizen',
                name                => 'create citizen',
                stash               => 'citizen',
                automatic_load_item => 0,
                [
                    name          => fake_name()->(),
                    politician_id => $politician_id,
                    fb_id         => "foobar",
                    origin_dialog => fake_words(1)->(),
                    gender        => fake_pick( qw/ M F/ )->(),
                    cellphone     => fake_digits("+551198#######")->(),
                    email         => fake_email()->(),
                ]
            ;

            my $recipient_id = stash 'citizen.id';
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
                    my $question_option = $schema->resultset('QuestionOption')->create(
                        {
                            question_id => $poll_question_id,
                            content     => $content,
                        },
                    ),
                    'add question option',
                );

                $text_to_options_id{$poll_question_id}->{$content} = $question_option->id;
            }
        }
    };

    subtest 'mocking results' => sub {

        # O recipient 1 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[0],
                    option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 1 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[0],
                    option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Não'},
                }
            ),
        );

        # O recipient 1 escolheu 'Talvez' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[0],
                    option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Sim' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Sim'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para 4 queijos.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    option_id  => $text_to_options_id{ $poll_questions[1]->id }->{'Talvez'},
                }
            ),
        );

        # O recipient 2 escolheu 'Não' para portuguesa.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[1],
                    option_id  => $text_to_options_id{ $poll_questions[2]->id }->{'Não'},
                }
            ),
        );

        # O recipient 3 escolheu 'Não' para frango com catupiry.
        ok(
            $schema->resultset('PollResult')->create(
                {
                    citizen_id => $recipient_ids[2],
                    option_id  => $text_to_options_id{ $poll_questions[0]->id }->{'Não'},
                }
            ),
        );
    };

    # Ok, agora tenho uma base de dados suficientemente populada para testar o filtro de tags.

    #api_auth_as user_id => $politician_id;
};

done_testing();

