use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => 'foo'
    );

    rest_get "/api/chatbot/",
        name    => "get on chatbot without security_token",
        is_fail => 1,
        code    => 400
    ;

    rest_get "/api/chatbot/",
        name    => "get on chatbot with wrong security_token",
        is_fail => 1,
        code    => 403,
        [ security_token => fake_words(3)->() ]
    ;

    rest_get "/api/chatbot",
        name    => "get on chatbot with correct security_token",
        [
            security_token => $security_token,
            fb_page_id     => 'foo'
        ]
    ;
};

done_testing();