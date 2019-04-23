use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = get_schema();

db_transaction {

    my ($res, $user, $user_id, $organization_id, $chatbot_id);
    subtest 'Create user and organization' => sub {
        $user            = create_user();
        $user_id         = $user->id;
        $organization_id = $user->organization->id;
    };


    subtest 'User | Get chatbot' => sub {
        api_auth_as user_id => $user_id;

        $res = $t->get_ok(
            "/organization/$organization_id/chatbot"
        )
        ->status_is(200)
        ->tx->res->json;

        ok( exists $res->{chatbots}->[0], 'one chatbot' );
        $chatbot_id = $res->{chatbots}->[0]->{id};

        $res = $t->get_ok(
            "/organization/$organization_id/chatbot/$chatbot_id"
        )
        ->status_is(200)
        ->json_has('/id')
        ->json_has('/name')
        ->json_has('/picture')
        ->json_has('/fb_config')
        ->json_has('/fb_config/access_token')
        ->json_has('/fb_config/page_id')
        ->json_is('/fb_config/access_token', undef)
        ->json_is('/fb_config/page_id', undef)
        ->tx->res->json;

        ok(ref $res->{fb_config} eq 'HASH', 'fb_config is a hash');
    };

    subtest 'User | Update chatbot' => sub {
        $t->put_ok(
            "/organization/$organization_id/chatbot/$chatbot_id",
            form => {
                page_id      => 'foobar',
                access_token => 'FOOBAR'
            }
        )
        ->status_is('202')
        ->json_has('/id');

        $t->get_ok(
            "/organization/$organization_id/chatbot/$chatbot_id"
        )
        ->status_is(200)
        ->json_is('/fb_config/access_token', 'FOOBAR')
        ->json_is('/fb_config/page_id', 'foobar');
    };
};

done_testing();
