use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $page_id = fake_words(1)->();
    create_politician(
        fb_page_id           => $page_id,
        fb_page_access_token => 'foo'
    );
    my $politician_id = stash "politician.id";

    my $item       = 'comment';
    my $post_id    = fake_words(1)->();
    my $comment_id = fake_words(1)->();
    my $permalink  = fake_words(1)->();

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without page_id',
        is_fail => 1,
        code    => 400,
        [
            item       => 'comment',
            post_id    => $post_id,
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without item',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply with invalid item',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'foobar',
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without post_id',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            item       => 'comment',
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without permalink',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'comment',
            comment_id => $comment_id,
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without matching page_id',
        is_fail => 1,
        code    => 400,
        [
            page_id    => 'foobar',
            post_id    => $post_id,
            item       => 'comment',
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply without comment_id when item is comment',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'comment',
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name                => 'sucessful private-reply creation',
        automatic_load_item => 0,
        [
            page_id    => $page_id,
            item       => 'comment',
            post_id    => $post_id,
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a alredy replied to comment',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'comment',
            comment_id => $comment_id,
            permalink  => fake_words(1)->()
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a post with comment_id',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'post',
            comment_id => $comment_id,
            permalink  => $permalink
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a post',
        automatic_load_item => 0,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'post',
            permalink  => fake_words(1)->()
        ]
    ;

    rest_post "/api/chatbot/private-reply",
        name    => 'private reply for a alredy responded to post',
        is_fail => 1,
        code    => 400,
        [
            page_id    => $page_id,
            post_id    => $post_id,
            item       => 'post',
            permalink  => fake_words(1)->()
        ]
    ;

};

done_testing();