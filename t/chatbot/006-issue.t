use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    my $recipient_fb_id = fake_words(1)->();
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
        name    => 'issue without message',
        is_fail => 1,
        code    => 400,
        [
            politician_id => $politician_id,
            fb_id        => $recipient_fb_id
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without politician_id',
        is_fail => 1,
        code    => 400,
        [
            fb_id   => $recipient_fb_id,
            message => fake_words(1)->()
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without fb_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id => $politician_id,
            message       => fake_words(1)->()
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without matching politician_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id => fake_words(1)->(),
            fb_id         => $recipient_fb_id,
            message       => fake_words(1)->()
        ]
    ;

    rest_post "/api/chatbot/issue",
        name    => 'issue without matching fb_id',
        is_fail => 1,
        code    => 400,
        [
            politician_id => $politician_id,
            fb_id         => fake_words(1)->(),
            message       => fake_words(1)->()
        ]
    ;

    my $big_message = fake_paragraphs(3)->();
    rest_post "/api/chatbot/issue",
        name    => 'issue with message bigger than 250 chars',
        is_fail => 1,
        code    => 400,
        [
            politician_id => $politician_id,
            fb_id         => $recipient_fb_id,
            message       => $big_message
        ]
    ;

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id => $politician_id,
            fb_id         => $recipient_fb_id,
            message       => fake_words(1)->()
        ]
    ;

    my $issue = $schema->resultset("Issue")->find(stash "i1.id");

    ok ($issue->open eq '1', 'Issue is created as open');
};

done_testing();