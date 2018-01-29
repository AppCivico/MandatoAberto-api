use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        [
            name          => "foobar",
            politician_id => $politician_id,
            fb_id         => "foobar",
            origin_dialog => "enquete"
        ]
    ;

    api_auth_as user_id => 1;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => 'direct message as admin',
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "Politician not premium",
        is_fail => 1,
        code    => 400,
        [
            name    => "Foobar",
            content => fake_words(2)->(),
        ]
    ;

    ok( $schema->resultset('Politician')->find($politician_id)->update( { premium => 1 } ) , 'politician premium');

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "politician without page",
        is_fail => 1,
        code    => 400,
    ;

    ok( $schema->resultset('Politician')->find($politician_id)->update( { fb_page_access_token => 'foobar' } ) , 'politician fb_page_access_token');

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message without content",
        is_fail => 1,
        code    => 400,
        [ name => "foobar" ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message without name",
        is_fail => 1,
        code    => 400,
        [ content => fake_words(2)->() ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message with invalid type of group",
        is_fail => 1,
        code    => 400,
        [
            name    => 'foobar',
            content => 'foobar',
            groups  => "['foobar']"
        ]
    ;

    rest_post "/api/politician/$politician_id/direct-message",
        name    => "creating direct message with unexistent group",
        is_fail => 1,
        code    => 400,
        [
            name    => 'foobar',
            content => 'foobar',
            groups  => "[99999999]"
        ]
    ;

    my $content = fake_words(2)->();
    my $name    = fake_words(1)->();

    # Criando grupos
    my $first_group_id = $schema->resultset("Group")->create(
        {
            politician_id => $politician_id,
            name          => fake_words(1)->(),
            filter        => '{}',
            created_at    => \'NOW()'
        }
    )->id;

    my $second_group_id = $schema->resultset("Group")->create(
        {
            politician_id => $politician_id,
            name          => fake_words(1)->(),
            filter        => '{}',
            created_at    => \'NOW()'
        }
    )->id;

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating direct message",
        automatic_load_item => 0,
        [
            name    => $name,
            content => $content,
            groups  => "[$first_group_id, $second_group_id]"
        ]
    ;

    rest_get "/api/politician/$politician_id/direct-message",
        name  => "get direct messages",
        list  => 1,
        stash => "get_direct_messages"
    ;

    stash_test "get_direct_messages" => sub {
        my $res = shift;

        is ($res->{direct_messages}->[0]->{name}, $name, 'dm name');
        is ($res->{direct_messages}->[0]->{content}, $content, 'dm content');
        is ($res->{direct_messages}->[0]->{count}, 1, 'dm count');

    };

};

done_testing();
