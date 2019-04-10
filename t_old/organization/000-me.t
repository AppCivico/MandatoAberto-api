use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    my ($user_id, $organization_id);
    subtest 'Create user and organization' => sub {
        $user_id         = create_user();
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
    };

    subtest 'User | Get organization - fail' => sub {
        # Sem login
        rest_get "/api/organization/$organization_id",
            is_fail => 1,
            code    => 403
        ;
    };

    subtest 'User | Get organization' => sub {
        api_auth_as user_id => $user_id;

        rest_get "/api/organization/$organization_id",
            code  => 200,
            stash => 'o1',
            list  => 1
        ;

        stash_test 'o1' => sub {
            my $res = shift;

            # TODO testar campos do retorno
        };
    };

    subtest 'User | Update organization' => sub {
        rest_put "/api/organization/$organization_id",
            code  => 200,
            params => [ name => 'fake_name' ],
            files => { file => "$Bin/picture.jpg", }
        ;

        rest_get "/api/organization/$organization_id",
            code  => 200,
            stash => 'o1',
            list  => 1
        ;

        stash_test 'o1' => sub {
            my $res = shift;
            # TODO testar campos do retorno
        };
    };
};

done_testing();
