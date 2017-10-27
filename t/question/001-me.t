use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    api_auth_as user_id => 1;

    rest_post "/api/register/dialog",
        name                => 'add dialog',
        automatic_load_item => 0,
        stash               => "dialog",
        [ name => 'Dialogo de teste' ]
    ;

    my $dialog_id = stash "dialog.id";

    rest_post "/api/register/question",
        name                => "Create a question",
        automatic_load_item => 0,
        [
            name      => "Pergunta de teste",
            content   => "Foo",
            dialog_id => $dialog_id
        ]
    ;

    rest_post "/api/register/question",
        name                => "Create another question",
        automatic_load_item => 0,
        [
            name      => "Outra pergutna de teste",
            content   => "Bar",
            dialog_id => $dialog_id
        ]
    ;

    rest_get "/api/question/",
        name  => "get dialog",
        list  => 1,
        stash => "get_dialog",
    ;
};

done_testing();