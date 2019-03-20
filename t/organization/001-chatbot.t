use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    my ($user_id, $organization_id, $chatbot_id);
    subtest 'Create user and organization' => sub {
        $user_id         = create_user();
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
    };


    subtest 'User | Get organization' => sub {
        api_auth_as user_id => $user_id;

        rest_get "/api/organization/$organization_id/chatbot",
            code  => 200,
            stash => 'cl1',
            list  => 1
        ;

        stash_test 'cl1' => sub {
            my $res = shift;

            ok( exists $res->{chatbots}->[0], 'one chatbot' );
            $chatbot_id = $res->{chatbots}->[0]->{id};

            # TODO testar campos do retorno
        };

        rest_get "/api/organization/$organization_id/chatbot/$chatbot_id",
            code  => 200,
            stash => 'c1',
            list  => 1
        ;

        stash_test 'c1' => sub {
            my $res = shift;

            # TODO testar campos do retorno
        };
    };
};

done_testing();
