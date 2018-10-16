use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $page_id = fake_words(1)->();
    create_politician(
        fb_page_id           => $page_id,
        fb_page_access_token => 'foo'
    );
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset("Politician")->find($politician_id);

    $politician->user->update( { approved => 1 } );

    my $item       = 'comment';
    my $post_id    = fake_words(1)->();
    my $comment_id = fake_words(1)->();
    my $permalink  = fake_words(1)->();

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without page_id',
        is_fail => 1,
        code    => 400,
        [
            item           => 'comment',
            post_id        => $post_id,
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without item',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'

        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply with invalid item',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'foobar',
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without post_id',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            item           => 'comment',
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without matching page_id',
        is_fail => 1,
        code    => 400,
        [
            page_id        => 'foobar',
            post_id        => $post_id,
            item           => 'comment',
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without comment_id when item is comment',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'comment',
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without user_id',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'comment',
            permalink      => $permalink,
            security_token => $security_token,
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name                => 'sucessful private-reply creation',
        automatic_load_item => 0,
        [
            page_id        => $page_id,
            item           => 'comment',
            post_id        => $post_id,
            comment_id     => $comment_id,
            permalink      => $permalink,
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a alredy replied to comment',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'comment',
            comment_id     => $comment_id,
            permalink      => fake_words(1)->(),
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a post',
        automatic_load_item => 0,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'post',
            permalink      => fake_words(1)->(),
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a alredy responded to post',
        is_fail => 1,
        code    => 400,
        [
            page_id        => $page_id,
            post_id        => $post_id,
            item           => 'post',
            permalink      => fake_words(1)->(),
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    # Desativando private reply para o político
    api_auth_as user_id => $politician_id;
    rest_put "/api/politician/$politician_id",
        name => 'Deactivating private replies',
        [ private_reply_activated => 0 ]
    ;

    ok ( $politician = $politician->discard_changes, 'discard changes' );
    is ( $politician->politician_private_reply_config->active, 0, 'private replies deactivated' );

    # Private reply foi criada no entanto não foi enviada
    rest_post "/api/chatbot/private-reply",
        name                => 'sucessful private-reply creation',
        automatic_load_item => 0,
        stash               => 'r1',
        [
            page_id        => $page_id,
            item           => 'post',
            post_id        => fake_words(2)->(),
            permalink      => fake_words(2)->(),
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    my $private_reply = $schema->resultset("PrivateReply")->find(stash 'r1.id');

    is ($private_reply->reply_sent, 0, 'reply was not sent');

    rest_put "/api/politician/$politician_id",
        name => 'Deactivating private replies',
        [ private_reply_activated => 1 ]
    ;

    ok ( $politician = $politician->discard_changes, 'discard changes' );
    is ( $politician->politician_private_reply_config->active, 1, 'private replies activated' );

    # Private reply foi criada no entanto não foi enviada por estar dentro do delay
    rest_post "/api/chatbot/private-reply",
        name                => 'sucessful private-reply creation',
        automatic_load_item => 0,
        stash               => 'r2',
        [
            page_id        => $page_id,
            item           => 'post',
            post_id        => '136021913750928_204125850273867',
            permalink      => fake_words(2)->(),
            security_token => $security_token,
            user_id        => 'foobar'
        ]
    ;

    my $delayed_private_reply = $schema->resultset("PrivateReply")->find(stash 'r2.id');

    is($delayed_private_reply->reply_sent, 0, 'reply was not sent');

};

done_testing();