use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    use_ok 'MandatoAberto::Worker::Campaign';

    my $worker = new_ok('MandatoAberto::Worker::Campaign', [ schema => $schema ]);
    ok( $worker->does('MandatoAberto::Worker'), 'worker does MandatoAberto::Worker' );

    create_politician(
        fb_page_id => 'foo'
    );
    my $politician_id = stash "politician.id";

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

	my $politician              = $schema->resultset('Politician')->find($politician_id);
	my $organization_chatbot_id = $politician->user->organization_chatbot_id;

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

    rest_post "/api/chatbot/recipient",
        name                => "Create first recipient",
        automatic_load_item => 0,
        stash               => "r1",
        [
            name           => fake_name()->(),
            politician_id  => $politician_id,
            fb_id          => fake_words(2)->(),
            origin_dialog  => "enquete",
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/recipient",
        name                => "Create second recipient",
        automatic_load_item => 0,
        stash               => "r2",
        [
            name           => fake_name()->(),
            politician_id  => $politician_id,
            fb_id          => fake_words(2)->(),
            origin_dialog  => "enquete",
            security_token => $security_token
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

    my $content = 'é um teste súpôm';
    my $name    = fake_words(1)->();

    # Criando grupos
    my $first_group_id = $schema->resultset("Group")->create(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => 'foobar',
            filter                  => '{}',
            status                  => 'ready',
        }
    )->id;

    my $second_group_id = $schema->resultset("Group")->create(
        {
            organization_chatbot_id => $organization_chatbot_id,
            name                    => fake_words(1)->(),
            filter                  => '{}',
            status                  => 'ready',
        }
    )->id;

    # Atrelando os recipientes aos grupos
    $schema->resultset("Recipient")->find(stash "r1.id")->update(
        { groups => "\"$first_group_id\"=>\"1\", \"$second_group_id\"=>\"1\"" }
    );

    $schema->resultset("Recipient")->find(stash "r2.id")->update(
        { groups => "\"$second_group_id\"=>\"1\"" }
    );

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating direct message",
        automatic_load_item => 0,
        stash               => 'dm1',
        [
            name    => $name,
            content => $content,
            groups  => "[$first_group_id]"
        ]
    ;

    ok( $worker->run_once(), 'run once' );

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
        is ($res->{direct_messages}->[0]->{groups}->[0]->{name}, 'foobar', 'group name');

        ok(defined $res->{direct_messages}->[0]->{created_at}, 'created_at is defined');
        ok(defined $res->{direct_messages}->[0]->{status},     'status is defined');
    };

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating another direct message",
        automatic_load_item => 0,
        [
            name    => 'foobar',
            content => 'foobar',
        ]
    ;

    ok( $worker->run_once(), 'run once' );

    rest_reload_list "get_direct_messages";
    stash_test "get_direct_messages.list" => sub {
        my $res = shift;

        is ($res->{direct_messages}->[1]->{name}, 'foobar', 'dm name');
        is ($res->{direct_messages}->[1]->{content}, 'foobar', 'dm content');
        is ($res->{direct_messages}->[1]->{count}, 2, 'dm count');
    };

    $schema->resultset("Recipient")->find(stash "r2.id")->update( { fb_opt_in => 0 } );

    rest_post "/api/politician/$politician_id/direct-message",
        name                => "creating yet another direct message",
        automatic_load_item => 0,
        [
            name    => 'foobar',
            content => 'foobar',
        ]
    ;

    ok( $worker->run_once(), 'run once' );

    rest_reload_list "get_direct_messages";
    stash_test "get_direct_messages.list" => sub {
        my $res = shift;

        is ($res->{direct_messages}->[2]->{name}, 'foobar', 'dm name');
        is ($res->{direct_messages}->[2]->{content}, 'foobar', 'dm content');
        is ($res->{direct_messages}->[2]->{count}, 1, 'dm count');
    };

    subtest 'some group is not ready' => sub {
        my $third_group = $schema->resultset("Group")->create(
            {
                organization_chatbot_id => $organization_chatbot_id,
                name                    => 'foobar',
                filter                  => '{}',
            }
        );

        my $third_group_id = $third_group->id;

        rest_post "/api/politician/$politician_id/direct-message",
            name    => "creating direct message when group is not ready --fail",
            is_fail => 1,
            [
                name    => $name,
                content => $content,
                groups  => "[$third_group_id]"
            ]
        ;
    };

    # Testando criação de mensagens diretas com imagem
    subtest 'direct message with attachment type' => sub {

        rest_post "/api/politician/$politician_id/direct-message",
            name    => 'POST without attachment url',
            params => [
                name            => 'foobar',
                type            => 'attachment',
                attachment_type => 'image',
            ],
            files => { file => "$Bin/picture.jpg" }
        ;

        ok( $worker->run_once(), 'run once' );

        rest_post "/api/politician/$politician_id/direct-message",
            name    => 'POST without attachment url',
            params => [
                name            => 'foobar',
                type            => 'attachment',
                attachment_type => 'image',
            ],
            files => { file => "$Bin/picture.jpg", },
        ;

        ok( $worker->run_once(), 'run once' );
    };

    subtest 'direct message without any required param' => sub {

        rest_post "/api/politician/$politician_id/direct-message",
            name    => 'POST without content or attachment',
            is_fail => 1,
            code    => 400,
            params => [ name => 'foobar' ],
        ;
    };

    subtest 'direct message with both content and attachment' => sub {

        rest_post "/api/politician/$politician_id/direct-message",
            name                => 'POST with content and attachment',
            automatic_load_item => 0,
            params              => [
                name            => 'foobar',
                content         => 'test',
                attachment_type => 'image',
            ],
            files => { file => "$Bin/picture.jpg", },
        ;

        ok( $worker->run_once(), 'run once' );
    };
};

done_testing();
