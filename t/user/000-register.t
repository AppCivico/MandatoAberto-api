use common::sense;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {
    subtest 'Register | User - Invalid' => sub {

        subtest 'Missing params' => sub {
            # Missing password
            $t->post_ok(
                '/user',
                form => {
                    name  => 'foobar',
                    email => 'lucas.ansei@appcivico.com'
                }
            )
            ->status_is(400)
            ->json_is('/error',            'form_error')
            ->json_is('/message/password', 'missing');

            # Missing name
            $t->post_ok(
                '/user',
                form => {
                    password => 'foobar',
                    email    => 'lucas.ansei@appcivico.com'
                }
            )
            ->status_is(400)
            ->json_is('/error',        'form_error')
            ->json_is('/message/name', 'missing');

            # Missing email
            $t->post_ok(
                '/user',
                form => {
                    name     => 'foobar',
                    password => 'foobar'
                }
            )
            ->status_is(400)
            ->json_is('/error',         'form_error')
            ->json_is('/message/email', 'missing');

        };

        subtest 'Invalid params' => sub {
            # Invalid password (6 chars min)
            $t->post_ok(
                '/user',
                form => {
                    name     => 'foobar',
                    password => '123',
                    email    => 'lucas.ansei@appcivico.com'
                }
            )
            ->status_is(400)
            ->json_is('/error',            'form_error')
            ->json_is('/message/password', 'invalid');

            # Invalid email
            $t->post_ok(
                '/user',
                form => {
                    name     => 'foobar',
                    password => '123',
                    email    => 'foobar'
                }
            )
            ->status_is(400)
            ->json_is('/error',         'form_error')
            ->json_is('/message/email', 'invalid');

            # Email alredy in use
            db_transaction{
                ok(
                    $schema->resultset('User')->create(
                        {
                            name     => 'foobar',
                            email    => 'lucas.ansei@appcivico.com',
                            password => '123456'
                        }
                    ),
                    'user created'
                );

                $t->post_ok(
                    '/user',
                    form => {
                        name     => 'foobar',
                        password => '123',
                        email    => 'lucas.ansei@appcivico.com'
                    }
                )
                ->status_is(400);
            };

            # Non existent invite token for organization
            $t->post_ok(
                '/user',
                form => {
                    name         => 'foobar',
                    password     => '123456',
                    email        => 'lucas.ansei@appcivico.com',
                    invite_token => 'foobar'
                }
            )
            ->status_is(400)
            ->json_is('/form_error/invite_token', 'invalid');
        };

        my $organization_rs                  = $schema->resultset('Organization');
        my $organization_chatbot_rs          = $schema->resultset('OrganizationChatbot');
        my $organization_general_config_rs   = $schema->resultset('OrganizationChatbotGeneralConfig');
        my $organization_general_facebook_rs = $schema->resultset('OrganizationChatbotFacebookConfig');
        my $user_organization_rs             = $schema->resultset('UserOrganization');

        my $organization;
        subtest 'Register | User' => sub {
            $t->post_ok(
                '/user',
                form => {
                    name     => 'Lucas Ansei',
                    password => 'fake_password',
                    email    => 'lucas.ansei@appcivico.com',
                }
            )
            ->status_is(201)
            ->json_has('/id');

            $organization = $organization_rs->next();

            is($organization_rs->count,         1, 'organization created');
            is($organization_chatbot_rs->count, 1, 'chatbot created');

            is(
                $user_organization_rs->search( { organization_id => $organization->id } )->count,
                1,
                'one member on the organization'
            );
        };

        ok( my $invite_token = $organization->invite_token, 'invite token' );

        subtest 'Register | User with invite' => sub {
            $t->post_ok(
                '/user',
                form => {
                    name         => 'Lucas Ansei 2',
                    password     => 'fake_password',
                    email        => 'lucas.ansei+2@appcivico.com',
                    invite_token => $invite_token
                }
            )
            ->status_is(201);

            is($organization_rs->count,         1, 'only one organization created');
            is($organization_chatbot_rs->count, 1, 'only one chatbot created');

            is(
                $user_organization_rs->search( { organization_id => $organization->id } )->count,
                2,
                'two members on the organization'
            );
        };
    };
};

done_testing();
