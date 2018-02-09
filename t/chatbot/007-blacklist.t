use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    my $recipient_fb_id = fake_words(1)->();
    create_recipient(
        politician_id => $politician_id,
        fb_id         => $recipient_fb_id
    );
    my $recipient_id = stash "recipient.id";

    rest_get "/api/chatbot/blacklist",
        name    => "blacklist without recipient_fb_id",
        is_fail => 1,
        code    => 400
    ;

    rest_get "/api/chatbot/blacklist",
        name  => "blacklist without recipient_fb_id",
        stash => "get_blacklist",
        [ fb_id => $recipient_fb_id ]
    ;
};

done_testing();