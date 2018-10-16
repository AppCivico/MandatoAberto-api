use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician( fb_page_id => 'politician_foobar' );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

	$politician->user->update( { approved => 1 } );

    # Adicionando um recipient.
    create_recipient( politician_id => $politician_id, fb_id => 'recipient_foobar', security_token => $security_token );
    my $recipient_id = stash 'recipient.id';

    # Criando uma pool.
    api_auth_as user_id => $politician_id;
    rest_post '/api/register/poll',
        name                => 'add pool',
        automatic_load_item => 0,
        stash               => 'add_pool',
        [
            name                       => 'Enquete',
            status_id                  => 1,
            'questions[0]'             => 'Você aprova o horário de verão?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
        ]
    ;

    rest_get "/api/chatbot/poll",
        name  => 'get poll',
        list  => 1,
        stash => 'get_poll',
        [
            fb_page_id     => 'politician_foobar',
            security_token => $security_token
        ]
    ;
    my $poll = stash 'get_poll';

    # Respondendo uma enquete.
    rest_post "/api/chatbot/poll-result",
        name                => 'add poll result',
        automatic_load_item => 0,
        [
            fb_id                   => 'recipient_foobar',
            poll_question_option_id => $poll->{questions}->[0]->{options}->[1]->{id},
            origin                  => 'dialog',
            security_token          => $security_token
        ]
    ;

    use_ok 'MandatoAberto::Worker::Segmenter';
    my $worker = new_ok('MandatoAberto::Worker::Segmenter', [ schema => $schema ]);

    # Adicionando grupo.
    rest_post "/api/politician/$politician_id/group",
        name    => 'add group',
        stash   => 'group',
        headers => [ 'Content-Type' => 'application/json' ],
        data    => encode_json({
            name     => 'AppCivico',
            filter   => {
                operator => 'AND',
                rules => [
                    {
                        name => 'QUESTION_ANSWER_EQUALS',
                        data => {
                            field => $poll->{questions}->[0]->{id},
                            value => 'Sim',
                        },
                    },
                ],
            },
        }),
    ;

    ok( $worker->run_once(), 'run once' );

    my $group_id = stash 'group.id';
    ok( my $group = $schema->resultset('Group')->search( { 'me.id' => $group_id } )->next, 'get group' );

    is( $group->recipients_count, 1, 'recipients_count=1' );
    is( $schema->resultset('Recipient')->search_by_group_ids($group_id)->count, 1, 'recipients_count=1' );

    subtest 'recipient with different answer' => sub {

        create_recipient( politician_id => $politician_id, fb_id => 'recipient2' );
        rest_post "/api/chatbot/poll-result",
            name                => 'add poll result',
            automatic_load_item => 0,
            [
                fb_id                   => 'recipient2',
                poll_question_option_id => $poll->{questions}->[0]->{options}->[0]->{id},
                origin                  => 'dialog',
                security_token          => $security_token
            ]
        ;

        is( $group->discard_changes->recipients_count, 1, 'recipients_count=1' );
        is( $schema->resultset('Recipient')->search_by_group_ids($group_id)->count, 1, 'recipients_count=1' );
    };

    subtest 'add new recipient to group' => sub {

        create_recipient( politician_id => $politician_id, fb_id => 'recipient3' );
        rest_post "/api/chatbot/poll-result",
            name                => 'add poll result',
            automatic_load_item => 0,
            [
                fb_id                   => 'recipient3',
                poll_question_option_id => $poll->{questions}->[0]->{options}->[1]->{id},
                origin                  => 'dialog',
                security_token          => $security_token
            ]
        ;

        is( $group->discard_changes->recipients_count, 2, 'recipients_count=2' );
        is( $schema->resultset('Recipient')->search_by_group_ids($group_id)->count, 2, 'recipients_count=2' );
    };

};

done_testing();