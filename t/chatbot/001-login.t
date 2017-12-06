use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email = fake_email()->();
    create_politician(
        email => $email
    );
    my $politician_id = stash "politician.id";


    rest_post "/api/login",
        name  => "Chatbot login",
        code  => 200,
        stash => 'l1',
        [
            email    => $email . '.chatbot',
            password => $email . '.chatbot'
        ]
    ;
};

done_testing();