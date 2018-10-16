use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician( fb_page_id => 'foobar' );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    create_recipient(
        politician_id  => $politician_id,
        security_token => $security_token
    );
    my $first_recipient_id = stash "recipient.id";

    create_recipient(
        politician_id  => $politician_id,
        security_token => $security_token
    );
    my $second_recipient_id = stash "recipient.id";

    api_auth_as user_id => $politician_id;

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => 'foobar',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
        ]
    ;
    my $poll_id = stash "p1.id";

    my $poll_question_option_id = $schema->resultset("PollQuestionOption")->search(undef)->next->id;

    rest_post "/api/politician/$politician_id/poll/$poll_id/propagate",
        name    => 'propagating poll without premium',
        is_fail => 1,
        code    => 400
    ;

    $schema->resultset("Politician")->find($politician_id)->update( { premium => 1 } );

    my $group_id = $schema->resultset("Group")->create(
        {
            politician_id => $politician_id,
            name          => 'foobar',
            filter        => '{}',
            status        => 'ready',
        }
    )->id;

    rest_post "/api/politician/$politician_id/poll/$poll_id/propagate",
        name    => "creating poll propagation with unexistent group",
        is_fail => 1,
        code    => 400,
        [ groups  => "[99999999]" ]
    ;

    # Atrelando o primeiro recipiente ao grupo
    $schema->resultset("Recipient")->find($first_recipient_id)->update(
        { groups => "\"$group_id\"=>\"1\"" }
    );

    rest_post "/api/politician/$politician_id/poll/$poll_id/propagate",
        name                => "creating poll propagation with group",
        automatic_load_item => 0,
        stash               => 'pp1',
        [ groups  => "[$group_id]" ]
    ;

    my $poll_result_rs = $schema->resultset("PollResult");
    ok( $poll_result_rs->create(
            {
                recipient_id            => $first_recipient_id,
                poll_question_option_id => $poll_question_option_id,
                origin                  => 'propagate'
            }
        ) , 'creating poll propagate response');

    rest_get "/api/politician/$politician_id/poll/propagate",
        name  => "get poll propagations",
        list  => 1,
        stash => "get_poll_propagation"
    ;

    stash_test "get_poll_propagation" => sub {
        my $res = shift;

        my $poll_propagation           = $res->{poll_propagations}->[0];
        my $first_poll_question_option = $poll_propagation->{poll}->{questions}->[0]->{options}->[0];

        is ( $poll_propagation->{id}, stash "pp1.id", 'poll propagation id' );
        is ( $poll_propagation->{poll}->{id}, $poll_id, 'poll id' );
        is ( $first_poll_question_option->{count}, 1, 'poll questions option chosen' );
    };
};

done_testing();