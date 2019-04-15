use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

use JSON;

db_transaction {
	my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot_id, $recipient_id, $recipient);
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user();
        $user_id         = $user_id->{id};
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
        $recipient    = $schema->resultset('Recipient')->create(
            {
                name                    => 'foo',
                fb_id                   => 'bar',
                page_id                 => 'foobar',
                organization_chatbot_id => $chatbot_id
            }
        );
        $recipient_id = $recipient->id;

        $schema->resultset('Politician')->create(
            {
                user_id          => $user_id,
                name             => 'foobar',
                gender           => 'M',
                address_state_id => 1,
                address_city_id  => 1,
            }
        )
    };

    subtest 'User | Create label' => sub {
        api_auth_as user_id => $user_id;

        # Ativando chatbot
        rest_put "/api/organization/$organization_id/chatbot/$chatbot_id",
            code => 200,
            [
                page_id      => 'fake_page_id',
                access_token => 'fake_access_token'
            ]
        ;

        # Criando label
        rest_post "/api/organization/$organization_id/chatbot/$chatbot_id/label",
            automatic_load_item => 0,
            [ name => 'foobar' ]
        ;

        rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/label";
    };

    subtest 'Chatbot | Label' => sub {
        subtest 'Add to label' => sub {
            is( $schema->resultset('RecipientLabel')->count, 0, 'no rows' );

            rest_post "/api/chatbot/recipient/",
                name => "change recipient data",
                [
                    chatbot_id     => $chatbot_id,
                    fb_id          => 'bar',
                    security_token => $security_token,
                    extra_fields   => encode_json(
                        {
                            custom_labels => [
                                { name => 'foobar' }
                            ],
                            system_labels => [
                                { name => 'fake_label' }
                            ]
                        }
                    ),
                ]
            ;

            is( $schema->resultset('RecipientLabel')->count, 2, '2 rows inserted' );
        };

        subtest 'Remove from label' => sub {
            is( $schema->resultset('RecipientLabel')->count, 2, '2 rows' );

            rest_post "/api/chatbot/recipient/",
                name => "change recipient data",
                [
                    chatbot_id     => $chatbot_id,
                    fb_id          => 'bar',
                    security_token => $security_token,
                    extra_fields   => encode_json(
                        {
                            custom_labels => [
                                { name => 'foobar' }
                            ],
                            system_labels => [
                                { name => 'fake_label', deleted => 1 }
                            ]
                        }
                    ),
                ]
            ;

            is( $schema->resultset('RecipientLabel')->count, 1, '1 row deleted' );
        };

        subtest 'Creating group with label' => sub {
            ok( my $label_id = $schema->resultset('Label')->search( { name => 'foobar' } )->next->id, 'label_id');
            is($recipient->groups, undef, 'no groups yet');

            rest_post "/api/politician/$user_id/group",
                name                => 'add group',
                stash               => 'group',
                automatic_load_item => 0,
                headers             => [ 'Content-Type' => 'application/json' ],
                data                => encode_json({
                    name     => 'Gender',
                    filter   => {
                        operator => 'AND',
                        rules => [
                            {
                                name => 'LABEL_IS',
                                data => { value => $label_id },
                            },
                        ],
                    },
                }),
            ;

            rest_post "/api/chatbot/recipient/",
                name => "change recipient data",
                [
                    chatbot_id     => $chatbot_id,
                    fb_id          => 'bar',
                    security_token => $security_token,
                    extra_fields   => encode_json(
                        {
                            custom_labels => [
                                { name => 'foobar' }
                            ],
                            system_labels => [
                                { name => 'fake_label' }
                            ]
                        }
                    ),
                ]
            ;

			ok($recipient = $recipient->discard_changes, 'discard changes');
            ok(defined $recipient->groups, 'recipient now part of a group');

        };
    };
};

done_testing();
