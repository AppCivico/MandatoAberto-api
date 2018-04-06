use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
        [
            origin_dialog  => fake_words(1)->(),
            politician_id  => $politician_id,
            name           => fake_name()->(),
            fb_id          => $recipient_fb_id,
            email          => fake_email()->(),
            cellphone      => fake_digits("+551198#######")->(),
            gender         => fake_pick( qw/F M/ )->(),
            security_token => $security_token
        ]
    ;

    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => $message,
            security_token => $security_token
        ]
    ;
    my $first_issue_id = stash "i1.id";

    rest_get "/api/politician/$politician_id/issue",
        name    => "get issues without login",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as "user_id" => $politician_id;

    rest_get "/api/politician/$politician_id/issue",
        name  => "get issues",
        list  => 1,
        stash => "get_issues"
    ;

    stash_test "get_issues" => sub {
        my $res = shift;

        my $open_issue = $res->{recipients}->[0]->{open_issues}->[0];

        is ($open_issue->{message},    $message, 'issue message');
        is ($open_issue->{reply},      undef,    'issue reply');
        is ($open_issue->{updated_at}, undef,    'issue updated timestamp');
    };

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue with reply with more than 250 chars",
        is_fail => 1,
        code    => 400,
        [ reply => fake_paragraphs(4)->() ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "ignoring issue without flag",
        is_fail => 1,
        code    => 400,
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue (ignoring) with reply",
        is_fail => 1,
        code    => 400,
        [
            ignore => 1,
            reply  => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name => "updating issue without reply",
        [ ignore => 1 ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue alredy closed",
        is_fail => 1,
        code    => 400
    ;

    rest_get "/api/politician/$politician_id/issue/$first_issue_id",
        name => "get only one issue",
    ;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;
    my $second_issue_id = stash "i2.id";

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i3",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token
        ]
    ;
    my $third_issue_id = stash "i3.id";

    # Criando um grupo para adicionar o recipiente
    # no fechamento da segunda issue
    my $group = $schema->resultset("Group")->create(
        {
            politician_id    => $politician_id,
            name             => 'foobar',
            filter           => '{}',
            status           => 'ready',
            recipients_count => 0
        }
    );

    my $group_id = $group->id;

    # Fechando uma issue e segmentando o recipient
    my $reply = fake_words(1)->();

    rest_put "/api/politician/$politician_id/issue/$second_issue_id",
        name => "updating issue without reply",
        [
            ignore => 0,
            groups => "[$group_id]",
            reply  => $reply
        ]
    ;

    is ($group->discard_changes->recipients_count, 1, 'one recipient on group');

    rest_reload_list "get_issues";

    stash_test "get_issues.list" => sub {
        my $res = shift;

        my $replied_issues = $res->{recipients}->[0]->{replied_issues};
        my $replied_issue  = $replied_issues->[0];

        my $ignored_issues = $res->{recipients}->[0]->{ignored_issues};
        my $ignored_issue  = $ignored_issues->[0];

        my $open_issues = $res->{recipients}->[0]->{open_issues};
        my $open_issue  = $open_issues->[0];

        my $groups = $res->{recipients}->[0]->{groups};
        my $group  = $groups->[0];

        is (scalar @{ $ignored_issues }, 1,               'one ignored issue');
        is ($ignored_issue->{id},        $first_issue_id, 'ignored issue id');

        is (scalar @{ $replied_issues }, 1,                'one replied issue');
        is ($replied_issue->{id},        $second_issue_id, 'replied issue id');
        is ($replied_issue->{reply},     $reply,           'replied issue reply text');

        is (scalar @{ $open_issues }, 1,               'one open issue');
        is ($open_issue->{id},        $third_issue_id, 'open issue id');

        is (scalar @{ $groups },   1,         'one group');
        is ($group->{id},          $group_id, 'group id');
        is ($group->{name},        'foobar',  'group name');
    };
};

done_testing();