use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
	my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

	my $politician    = create_politician(fb_page_id => 'foo');
	my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    my ( $recipient_id, $second_recipient_id );
    subtest 'Chatbot | Create recipients' => sub {
        $t->post_ok(
            '/api/chatbot/recipient',
            form => {
				name           => fake_name()->(),
                politician_id  => $politician_id,
                fb_id          => fake_words(2)->(),
                origin_dialog  => "enquete",
                security_token => $security_token
            }
        )
        ->status_is(201);
        $recipient_id = $t->tx->res->json->{id};

		$t->post_ok(
			'/api/chatbot/recipient',
			form => {
				name           => fake_name()->(),
				politician_id  => $politician_id,
				fb_id          => fake_words(2)->(),
				origin_dialog  => "enquete",
				security_token => $security_token
			}
		)->status_is(201);
		$second_recipient_id = $t->tx->res->json->{id};
    };

    subtest 'Admin | Create direct message' => sub {
        api_auth_as user_id => 1;

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
        )
        ->status_is(403);
    };

    subtest 'Politician | Create direct message' => sub {
        api_auth_as user_id => $politician_id;

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
				name    => "Foobar",
                content => fake_words(2)->(),
            }
        )
        ->status_is(400)
        ->json_is('/form_error/premium', 'politician is not premium', 'politician is not premium');

        ok( $schema->resultset('Politician')->find($politician_id)->update( { premium => 1 } ), 'politician premium');

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
        )
        ->status_is(400);

        ok( $schema->resultset('Politician')->find($politician_id)->update( { fb_page_access_token => 'foobar' } ), 'politician fb_page_access_token');

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => { name => 'Foobar' }
        )
        ->status_is(400)
        ->json_is('/form_error/content', 'missing', 'content is required');

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
                name    => 'foobar',
                content => 'foobar',
                groups  => "['foobar']"
            }
        )
        ->status_is(400)
        ->json_is('/form_error/groups', 'invalid', 'sending string instead of group_id');

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
                name    => 'foobar',
                content => 'foobar',
                groups  => "[99999999]"
            }
        )
        ->status_is(400)
        ->json_is('/form_error/groups', 'group 99999999 does not exists or does not belongs to this politician', 'creating direct message with unexistent group');

		my $content = fake_words(2)->();
		my $name    = fake_words(1)->();

        # Criando grupos
		my $first_group_id = $schema->resultset("Group")->create(
			{
				politician_id => $politician_id,
				name          => 'foobar',
				filter        => '{}',
				status        => 'ready',
			}
		)->id;

        my $second_group_id = $schema->resultset("Group")->create(
            {
                politician_id => $politician_id,
                name          => fake_words(1)->(),
                filter        => '{}',
                status        => 'ready',
            }
        )->id;

        # Atrelando os recipientes aos grupos
        $schema->resultset("Recipient")->find($recipient_id)->update(
            { groups => "\"$first_group_id\"=>\"1\", \"$second_group_id\"=>\"1\"" }
        );

        $schema->resultset("Recipient")->find($second_recipient_id)->update(
            { groups => "\"$second_group_id\"=>\"1\"" }
        );

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
				name    => $name,
                content => $content,
                groups  => "[$first_group_id]"
            }
        )
        ->status_is(201)
        ->json_has('/id', 'dm id');

        $t->get_ok(
            "/api/politician/$politician_id/direct-message"
        )
        ->status_is(200)
		->json_is('/direct_messages/0/name',          $name,    'dm name')
		->json_is('/direct_messages/0/content',       $content, 'dm content')
		->json_is('/direct_messages/0/count',         1,        'dm count')
		->json_is('/direct_messages/0/groups/0/name', 'foobar', 'group name');

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
				name    => 'foobar',
                content => 'foobar'
            }
        )
        ->status_is(201)
        ->json_has('/id', 'dm id');

        $t->get_ok(
            "/api/politician/$politician_id/direct-message"
        )
        ->status_is(200)
		->json_is('/direct_messages/1/name',    'foobar', 'dm name')
		->json_is('/direct_messages/1/content', 'foobar', 'dm content')
		->json_is('/direct_messages/1/count',   2,        'dm count');

        $schema->resultset("Recipient")->find($second_recipient_id)->update( { fb_opt_in => 0 } );

        $t->post_ok(
            "/api/politician/$politician_id/direct-message",
            form => {
				name    => 'foobar',
                content => 'foobar'
            }
        )
        ->status_is(201)
        ->json_has('/id', 'dm id');

        $t->get_ok(
            "/api/politician/$politician_id/direct-message"
        )
        ->status_is(200)
		->json_is('/direct_messages/2/name',    'foobar', 'dm name')
		->json_is('/direct_messages/2/content', 'foobar', 'dm content')
		->json_is('/direct_messages/2/count',   1,        'dm count');

        subtest 'some group is not ready' => sub {
			my $third_group = $schema->resultset("Group")->create(
				{
					politician_id => $politician_id,
					name          => 'foobar',
					filter        => '{}',
				}
			);
            my $third_group_id = $third_group->id;

            $t->post_ok(
                "/api/politician/$politician_id/direct-message",
                form => {
                    name    => $name,
                    content => $content,
                    groups  => "[$third_group_id]"
                }
            )
            ->status_is(400)
            ->json_is('/form_error/groups', "group $third_group_id isn't ready", 'third group is not ready');
        };

        subtest 'direct message with attachment' => sub {
            $t->post_ok(
                "/api/politician/$politician_id/direct-message",
                form => {
                    name    => 'wrong',
                    content => 'foobar',
                    type    => 'attachment'
                }
            )
            ->status_is(400)
            ->json_is('/form_error/attachment_type', 'missing', 'attachment_type missing');

            $t->post_ok(
                "/api/politician/$politician_id/direct-message",
                form => {
                    name    => 'wrong',
                    content => 'foobar',
                    type    => 'attachment'
                }
            )
            ->status_is(400)
            ->json_is('/form_error/attachment_type', 'missing', 'attachment_type missing');

            $t->post_ok(
                "/api/politician/$politician_id/direct-message",
                form => {
					name            => 'foobar',
					content         => 'foobar',
					type            => 'attachment',
					attachment_type => 'image'
                }
            )
            ->status_is(400)
            ->json_is('/form_error/content', 'must not send content if direct message type is attachment', 'must not send content if direct message type is attachment');

            $t->post_ok(
                "/api/politician/$politician_id/direct-message",
                form => {
					name            => 'foobar',
					type            => 'attachment',
					attachment_type => 'image',
                },
                file => "$Bin/picture.jpg"
            )
            ->status_is(201)
            ->json_has('/id', 'id');



            use DDP; p $t->tx->res->json;
        }
    };
};

done_testing();
