use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    subtest 'Register | User - Invalid' => sub {

        subtest 'Missing params' => sub {
            # Missing password
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    name  => 'foobar',
                    email => 'lucas.ansei@appcivico.com'
                ]
            ;

            # Missing name
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    password => 'foobar',
                    email    => 'lucas.ansei@appcivico.com'
                ]
            ;

            # Missing email
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    name     => 'foobar',
                    password => 'foobar'
                ]
            ;
        };

        subtest 'Invalid params' => sub {
            # Invalid password (6 chars min)
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    name     => 'foobar',
                    password => '123',
                    email    => 'lucas.ansei@appcivico.com'
                ]
            ;

            # Invalid email
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    name     => 'foobar',
                    password => '123456',
                    email    => 'foobar'
                ]
            ;

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

                rest_post '/api/register',
                    is_fail => 1,
                    code    => 400,
                    [
                        name     => 'foobar',
                        password => '123456',
                        email    => 'lucas.ansei@appcivico.com'
                    ]
                ;
            };

            # Non existent invite token for organization
            rest_post '/api/register',
                is_fail => 1,
                code    => 400,
                [
                    name         => 'foobar',
                    password     => '123456',
                    email        => 'lucas.ansei@appcivico.com',
                    invite_token => 'foobar'
                ]
            ;

        };

        my $organization_rs                  = $schema->resultset('Organization');
        my $organization_chatbot_rs          = $schema->resultset('OrganizationChatbot');
        my $organization_general_config_rs   = $schema->resultset('OrganizationChatbotGeneralConfig');
        my $organization_general_facebook_rs = $schema->resultset('OrganizationChatbotFacebookConfig');
        my $user_organization_rs             = $schema->resultset('UserOrganization');

        my $organization;
        subtest 'Register | User' => sub {
            rest_post '/api/register',
                is_fail             => 0,
                automatic_load_item => 0,
                code                => 201,
                [
                    name     => 'Lucas Ansei',
                    password => 'fake_password',
                    email    => 'lucas.ansei@appcivico.com',
                ]
            ;

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
            rest_post '/api/register',
                is_fail             => 0,
                automatic_load_item => 0,
                code                => 201,
                [
                    name         => 'Lucas Ansei 2',
                    password     => 'fake_password',
                    email        => 'lucas.ansei+2@appcivico.com',
                    invite_token => $invite_token
                ]
            ;

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
