use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use JSON qw(to_json);

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

use_ok 'MandatoAberto::Worker::Segmenter';
my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
            create_recipient(
                politician_id  => $politician_id,
                security_token => $security_token
            );

            my $recipient_id = stash 'recipient.id';
            push @recipient_ids, $recipient_id;
        }
    };

    my $poll;
    subtest 'mocking poll' => sub {
        ok(
            $poll = $schema->resultset('Poll')->create(
                {
                    name                    => 'Pizza',
                    organization_chatbot_id => $organization_chatbot_id,
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
            [ sort map { $_->id } $schema->resultset('Recipient')->search_by_group_ids($group_id)->all ],
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

db_transaction {
    api_auth_as user_id => 1;

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    activate_chatbot($politician_id);

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $first_recipient_id = stash "recipient.id";

    create_recipient(
        politician_id => $politician_id,
        gender        => 'M'
    );
    my $second_recipient_id = stash "recipient.id";

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $third_recipient_id = stash "recipient.id";

    # Esses filtros selecionam os recipients por gênero
    db_transaction {
        rest_post "/api/politician/$politician_id/group",
            name                => 'add group (gender is)',
            stash               => 'group',
            automatic_load_item => 0,
            headers             => [ 'Content-Type' => 'application/json' ],
            data                => encode_json({
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

        my $group_id = stash 'group.id';

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 2, 'recipient count');
    };

    db_transaction {
        rest_post "/api/politician/$politician_id/group",
            name                => 'add group (gender is not)',
            stash               => 'group',
            automatic_load_item => 0,
            headers             => [ 'Content-Type' => 'application/json' ],
            data                => encode_json({
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

        my $group_id = stash 'group.id';

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 1, 'recipient count');
    };

};

db_transaction {
    api_auth_as user_id => 1;

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $first_recipient_id = stash "recipient.id";
    my $first_recipient    = $schema->resultset('Recipient')->find($first_recipient_id);

    create_recipient(
        politician_id => $politician_id,
        gender        => 'M'
    );
    my $second_recipient_id = stash "recipient.id";

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $third_recipient_id = stash "recipient.id";

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $first_recipient->fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
                {
    "responseId" => "f51c7faf-7569-425c-898e-f1130f17960b-7e4f1f27",
    "queryResult" => {
        "fulfillmentMessages" => [
            {
                "platform" => "PLATFORM_UNSPECIFIED",
                "text" => {
                    "text" => ["Lamento, mas não compreendi."]
                },
                "message" => "text"
            }
        ],
        "outputContexts" => [],
        "queryText" => "O que você acha do aborto?",
        "speechRecognitionConfidence" => 0,
        "action" => "input.unknown",
        "parameters" => {
            "fields" => {}
        },
        "allRequiredParamsPresent" => 1,
        "fulfillmentText" => "Lamento, mas não compreendi.",
        "webhookSource" => "",
        "webhookPayload" => undef,
        "intent" => {
            "inputContextNames" => [],
            "events" => [],
            "trainingPhrases" => [],
            "outputContexts" => [],
            "parameters" => [],
            "messages" => [],
            "defaultResponsePlatforms" => [],
            "followupIntentInfo" => [],
            "name" => "projects/dipiou-eivcjk/agent/intents/1f450a68-c73f-4419-8366-3c8b6fb4299a",
            "displayName" => "direitos_animais",
            "priority" => 0,
            "isFallback" => 1,
            "webhookState" => "WEBHOOK_STATE_UNSPECIFIED",
            "action" => "",
            "resetContexts" => 0,
            "rootFollowupIntentName" => "",
            "parentFollowupIntentName" => "",
            "mlDisabled" => 0
        },
        "intentDetectionConfidence" => 1,
        "diagnosticInfo" => undef,
        "languageCode" => "pt-br"
    },
    "webhookStatus" => undef
}
            )
        ],
    ;

    my $politician              = $schema->resultset('Politician')->find($politician_id);
    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    my $entity = $schema->resultset('PoliticianEntity')->search(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => 'direitos_animais'
        }
    )->next;

    # Esses filtros selecionam os recipients por gênero
    db_transaction {
        rest_post "/api/politician/$politician_id/group",
            name                => 'add group (intent is)',
            stash               => 'group',
            automatic_load_item => 0,
            headers             => [ 'Content-Type' => 'application/json' ],
            data                => encode_json({
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
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 1, 'recipient count');
    };

    db_transaction {
        rest_post "/api/politician/$politician_id/group",
            name                => 'add group (intent is not)',
            stash               => 'group',
            automatic_load_item => 0,
            headers             => [ 'Content-Type' => 'application/json' ],
            data                => encode_json({
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

        my $group_id = stash 'group.id';

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

        is ($group->discard_changes->recipients_count, 2, 'recipient count');
    };

    # Grupo por label
    db_transaction{
        my $organization_id = $schema->resultset('Organization')->next->id;
        my $chatbot_id      = $schema->resultset('OrganizationChatbot')->next->id;

        rest_post "/api/organization/$organization_id/chatbot/$chatbot_id/label",
            automatic_load_item => 0,
            [ name => 'foobar' ]
        ;
        is $schema->resultset('Group')->count, 1;
        ok $schema->resultset('Group')->delete;

        my $label_id = $schema->resultset('Label')->next->id;
        $schema->resultset('RecipientLabel')->create( { label_id => $label_id, recipient_id => $first_recipient_id } );

        rest_post "/api/politician/$politician_id/group",
            name                => 'add group (intent is not)',
            stash               => 'group',
            automatic_load_item => 0,
            headers             => [ 'Content-Type' => 'application/json' ],
            data                => to_json({
                name     => 'Gender',
                filter   => {
                    operator => 'AND',
                    rules => [
                        {
                            name => 'LABEL_IS',
                            data => { value => $label_id },
                        },
                    ],
                },
            }),
        ;

        ok( $worker->run_once(), 'run once' );

        my $group_id = stash 'group.id';

        ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );
        is($group->discard_changes->recipients_count, 1, 'recipient count');
    };

};

db_transaction {
    api_auth_as user_id => 1;

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $first_recipient_id = stash "recipient.id";
    my $first_recipient    = $schema->resultset('Recipient')->find($first_recipient_id);

    create_recipient(
        politician_id => $politician_id,
        gender        => 'M'
    );
    my $second_recipient_id = stash "recipient.id";

    create_recipient(
        politician_id => $politician_id,
        gender        => 'F'
    );
    my $third_recipient_id = stash "recipient.id";

    my $politician              = $schema->resultset('Politician')->find($politician_id);
    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    # Criando grupos vazios e preenchendo manualmente
    # estes grupos não devem ser atualizados pelo daemon

    rest_post "/api/politician/$politician_id/group",
        name                => 'add group (intent is not)',
        stash               => 'group',
        automatic_load_item => 0,
        headers             => [ 'Content-Type' => 'application/json' ],
        data                => encode_json({
            name     => 'AppCivico',
            filter   => {},
        }),
    ;

    ok( $worker->run_once(), 'run once' );

    my $group_id = stash 'group.id';

    ok( my $group = $schema->resultset("Group")->find($group_id), 'get group' );

    is ($group->discard_changes->recipients_count, 0, 'recipient count');
    rest_post "/api/politician/$politician_id/recipients/$first_recipient_id/group",
        name => "adding recipient to group",
        code => 200,
        [ groups => "[$group_id]" ]
    ;

    is ($group->discard_changes->recipients_count, 1, 'recipient count');
};


done_testing();
