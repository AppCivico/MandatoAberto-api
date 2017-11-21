use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => 1;
    rest_post "/api/politician/$politician_id/biography",
        name    => "politician biography as admin",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/biography",
        name    => "biography without content",
        is_fail => 1,
        code    => 400
    ;

    rest_post "/api/politician/$politician_id/biography",
        name    => "biography with content with more than 640 chars",
        is_fail => 1,
        code    => 400,
        [ content => fake_paragraphs(5)->() ]
    ;

    my $biography_content = fake_sentences(1)->();
    rest_post "/api/politician/$politician_id/biography",
        name                => "biography sucessful creation",
        automatic_load_item => 0,
        stash               => 'b1',
        [ content => $biography_content ]
    ;

    my $biography_id = stash "b1.id";

    rest_get "/api/politician/$politician_id/biography",
        name  => "get biography",
        list  => 1,
        stash => "get_biography"
    ;

    stash_test "get_biography" => sub {
        my $res = shift;

        is ($res->{id}, $biography_id, 'id');
        is ($res->{politician_id}, $politician_id, 'politician_id');
        is ($res->{content}, $biography_content, 'content');
    };

    api_auth_as user_id => 1;

    rest_put "/api/politician/$politician_id/biography/$biography_id",
        name    => "PUT biography as admin",
        is_fail => 1,
        code    => 403,
    ;

    rest_get "/api/politician/$politician_id/biography",
        name    => "GET biography as admin",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as user_id => $politician_id;

    rest_put "/api/politician/$politician_id/biography/$biography_id",
        name => "PUT biography",
        [ content => "foobar" ]
    ;

    rest_reload_list "get_biography";

    stash_test "get_biography.list" => sub {
        my $res = shift;

        is ($res->{id}, $biography_id, 'biography id');
        is ($res->{politician_id}, $politician_id, 'politician id');
        is ($res->{content}, "foobar", 'biography content');
    };
};

done_testing();