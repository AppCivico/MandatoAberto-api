use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {

    my ($user, $organization_id);
    subtest 'Create user and organization' => sub {
        $user            = create_user();
        $organization_id = $user->organization->id;
    };

    subtest 'User | Get organization - fail' => sub {
        # Sem login
        $t->get_ok(
            "/organization/$organization_id"
        )
        ->status_is(403)
        ->json_is('/error', 'Forbidden');
    };

    subtest 'User | Get organization' => sub {
        my $user_id = $user->id;
        api_auth_as user_id => $user_id;

        $t->get_ok(
            "/organization/$organization_id"
        )
        ->status_is(200)
        ->json_has('/approved')
        ->json_has('/approved_at')
        ->json_has('/created_at')
        ->json_has('/id')
        ->json_has('/invite_token')
        ->json_has('/name')
        ->json_has('/picture')
        ->json_has('/premium')
        ->json_has('/premium_updated_at')
        ->json_has('/updated_at')
        ->json_has('/chatbots')
        ->json_has('/chatbots/0/dialogflow_config_id')
        ->json_has('/chatbots/0/fb_access_token')
        ->json_has('/chatbots/0/fb_page_id')
        ->json_has('/chatbots/0/id')
        ->json_has('/chatbots/0/name')
        ->json_has('/chatbots/0/picture')
        ->json_has('/chatbots/0/use_dialogflow');

    };

    subtest 'User | Update organization' => sub {
        $t->put_ok(
            "/organization/$organization_id",
            form => {
                name    => 'fake_name',
                picture => { file => "$Bin/../data/picture.jpg" }
            }
        )
        ->status_is(202);

        $t->get_ok(
            "/organization/$organization_id"
        )
        ->status_is(200)
        ->json_is('/name',    'fake_name')
        ->json_is('/picture', 'www.google.com');
    };
};

done_testing();
