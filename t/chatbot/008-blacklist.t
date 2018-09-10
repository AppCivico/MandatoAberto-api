use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => 'foo',
    );
    my $politician_id = stash "politician.id";

    create_recipient(
        politician_id => $politician_id,
    );
    my $recipient_id = stash "recipient.id";

    my $recipient_fb_id = $schema->resultset("Recipient")->find($recipient_id)->fb_id;

    rest_get "/api/chatbot/blacklist",
        name    => "blacklist without recipient_fb_id",
        is_fail => 1,
        code    => 400,
        [ security_token => $security_token ]

    ;

    rest_get "/api/chatbot/blacklist",
        name    => "blacklist with invalid recipient_fb_id",
        is_fail => 1,
        code    => 400,
        [
            fb_id          => 'foobar',
            security_token => $security_token
        ]
    ;

    rest_get "/api/chatbot/blacklist",
        name  => "get blacklist",
        stash => "get_blacklist",
        list  => 1,
        [
            fb_id          => $recipient_fb_id,
            security_token => $security_token
        ]
    ;

    stash_test "get_blacklist" => sub {
        my $res = shift;

        is ($res->{opt_in}, 1, 'recipient is opt_in');
        is ($res->{blacklist_entry_id}, undef, 'undefined blacklist_entry_id');
    };

    rest_post "/api/chatbot/blacklist",
        name    => "blacklist entry without fb_id",
        is_fail => 1,
        code    => 400,
        [ security_token => $security_token ]

    ;

    rest_post "/api/chatbot/blacklist",
        name    => "blacklist entry with invalid fb_id",
        is_fail => 1,
        code    => 400,
        [
            fb_id          => 'foobar',
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/blacklist",
        name                => "sucessful blacklist entry",
        stash               => "b1",
        code                => 200,
        automatic_load_item => 0,
        [
            fb_id          => $recipient_fb_id,
            security_token => $security_token
        ]
    ;
    my $blacklist_entry_id = stash "b1.id";

    rest_post "/api/chatbot/blacklist",
        name                => "duplicate blacklist entry",
        code                => 200,
        automatic_load_item => 0,
        [
            fb_id          => $recipient_fb_id,
            security_token => $security_token
        ]
    ;

};

done_testing();