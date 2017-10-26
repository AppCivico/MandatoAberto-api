use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_question(

    );

    rest_get "/api/question/",
        name  => "get dialog",
        list  => 1,
        stash => "get_dialog",
    ;
};

done_testing();