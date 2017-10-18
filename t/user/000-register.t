use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email = fake_email()->();

    rest_post "/api/register",
        stash               => "d1",
        automatic_load_item => 0,
        params              => {
            email    => $email,
            password => '1234567',
        }
    ;

};

done_testing();