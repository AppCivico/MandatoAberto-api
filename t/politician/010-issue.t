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
            security_token => $security_token,
            entities       => encode_json(
                {
                    Saude => [
                        'vacinacao',
                        'posto de saude'
                    ]
                }
            )
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
        stash => "get_issues",
        [ filter => 'open' ]
    ;

    stash_test "get_issues" => sub {
        my $res = shift;

        is ($res->{issues}->[0]->{message}, $message, 'issue message');
        is ($res->{issues}->[0]->{open},  1, 'issue status');
        is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
        is ($res->{issues}->[0]->{updated_at}, undef, 'issue updated timestamp');
        is ($res->{issues}->[0]->{ignored}, 0, 'issue is not ignored');
        is ($res->{issues}->[0]->{replied}, 0, 'issue is not replied');
    };

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue with reply with more than 2000 chars",
        is_fail => 1,
        code    => 400,
        [ reply => fake_paragraphs(100)->() ]
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
        name  => "get only one issue",
        stash => 'r1'
    ;

    stash_test 'r1' => sub {
        my $res = shift;

        is ( $res->{ignored}, 1, 'issue was ignored' );
    };

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
                {
                    Saude => [
                        'vacinacao',
                        'posto de saude'
                    ]
                }
            )
        ]
    ;
    my $second_issue_id = stash "i2.id";

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
    rest_put "/api/politician/$politician_id/issue/$second_issue_id",
        name => "updating issue without reply",
        [
            ignore => 0,
            groups => "[$group_id]",
            reply  => fake_words(1)->()
        ]
    ;

    is ($group->discard_changes->recipients_count, 1, 'one recipient on group');

    # Respondendo issue com mídia
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i3",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
                {
                    Saude => [
                        'vacinacao',
                        'posto de saude'
                    ]
                }
            )
        ]
    ;
    my $third_issue_id = stash "i3.id";

    rest_put "/api/politician/$politician_id/issue/$third_issue_id",
        name  => "updating issue with media",
        files => { file => "$Bin/picture.jpg", },
        [
            reply  => fake_words(1)->()
        ],
    ;

    my $third_issue = $schema->resultset('Issue')->find($third_issue_id);

    ok ( defined( $third_issue->saved_attachment_id ), 'defined' );

    # Por enquanto apenas os issues abertos serão listados

    # rest_reload_list "get_issues";

    # stash_test "get_issues.list" => sub {
    #     my $res = shift;

    #     is ($res->{issues}->[0]->{message}, $message, 'issue message');
    #     is ($res->{issues}->[0]->{open},  0, 'issue status');
    #     is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
    # };

    # rest_post "/api/chatbot/issue",
    #     name                => "issue creation",
    #     automatic_load_item => 0,
    #     stash               => "i2",
    #     [
    #         politician_id => $politician_id,
    #         fb_id         => $recipient_fb_id,
    #         message       => $message
    #     ]
    # ;
    # my $second_issue_id = stash "i2.id";

    # rest_reload_list "get_issues";

    # stash_test "get_issues.list" => sub {
    #     my $res = shift;

    #     is ($res->{issues}->[1]->{message}, $message, 'issue message');
    #     is ($res->{issues}->[1]->{open},  1, 'issue status');
    #     is ($res->{issues}->[1]->{reply}, undef, 'issue reply');
    # };

    # my $reply = fake_words(2)->();
    # rest_put "/api/politician/$politician_id/issue/$second_issue_id",
    #     name => 'updating second issue',
    #     [ reply => $reply ]
    # ;

    # rest_reload_list "get_issues";

    # stash_test "get_issues.list" => sub {
    #     my $res = shift;

    #     is ($res->{issues}->[1]->{message}, $message, 'issue message');
    #     is ($res->{issues}->[1]->{open},  0, 'issue status');
    #     is ($res->{issues}->[1]->{reply}, $reply, 'issue reply');
    # };
};

done_testing();