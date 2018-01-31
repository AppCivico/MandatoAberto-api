use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $page_id         = fake_words(1)->();
    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    create_politician(
        fb_page_id => $page_id 
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => $recipient_fb_id,
            email         => fake_email()->(),
            cellphone     => fake_digits("+551198#######")->(),
            gender        => fake_pick( qw/F M/ )->()
        ]
    ;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            page_id => $page_id,
            fb_id   => $recipient_fb_id,
            message => $message
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

        is ($res->{issues}->[0]->{message}, $message, 'issue message');
        is ($res->{issues}->[0]->{open},  1, 'issue status');
        is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
        is ($res->{issues}->[0]->{updated_at}, undef, 'issue updated timestamp');
    };

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue with reply with more than 250 chars",
        is_fail => 1,
        code    => 400,
        [ reply => fake_paragraphs(4)->() ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name => "updating issue without reply",
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue alredy closed",
        is_fail => 1,
        code    => 400
    ;

    rest_reload_list "get_issues";

    stash_test "get_issues.list" => sub {
        my $res = shift;

        is ($res->{issues}->[0]->{message}, $message, 'issue message');
        is ($res->{issues}->[0]->{open},  0, 'issue status');
        is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
    };

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            page_id => $page_id,
            fb_id   => $recipient_fb_id,
            message => $message
        ]
    ;
    my $second_issue_id = stash "i2.id";

    rest_reload_list "get_issues";

    stash_test "get_issues.list" => sub {
        my $res = shift;

        is ($res->{issues}->[1]->{message}, $message, 'issue message');
        is ($res->{issues}->[1]->{open},  1, 'issue status');
        is ($res->{issues}->[1]->{reply}, undef, 'issue reply');
    };

    my $reply = fake_words(2)->();
    rest_put "/api/politician/$politician_id/issue/$second_issue_id",
        name => 'updating second issue',
        [ reply => $reply ]
    ;

    rest_reload_list "get_issues";

    stash_test "get_issues.list" => sub {
        my $res = shift;

        is ($res->{issues}->[1]->{message}, $message, 'issue message');
        is ($res->{issues}->[1]->{open},  0, 'issue status');
        is ($res->{issues}->[1]->{reply}, $reply, 'issue reply');
    };
};

done_testing();