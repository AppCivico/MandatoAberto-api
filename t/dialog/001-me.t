use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_dialog(
        name => "Dialogo foo"
    );
    my $dialog_id = stash "dialog.id";

    rest_get "/api/dialog/",
        name  => "get dialog",
        list  => 1,
        stash => "get_dialog",
    ;

    stash_test "get_dialog" => sub {
        my $res = shift;

        # Dialogs without questions
        is_deeply(
            $res,
            {
                dialogs => [
                    {
                        id        => $dialog_id,
                        name      => "Dialogo foo",
                        questions => [ ]
                    }
                ]
            },
            'get_dialog expected response'
        );
    };

    rest_put "/api/dialog/$dialog_id",
        name    => "PUT first dialog with same name",
        is_fail => 1,
        code    => 400,
        [name => "Dialogo foo"]
    ;

    rest_put "/api/dialog/$dialog_id",
        name => "PUT first dialog",
        [name => "foobar"]
    ;

    rest_get "/api/dialog/",
        name  => "get dialog",
        list  => 1,
        stash => "get_updated_dialogs",
    ;

    stash_test "get_updated_dialogs" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                dialogs => [
                    {
                        id   => $dialog_id,
                        name => "foobar",
                        questions => [ ]
                    },
                ]
            },
            'get_updated_dialog expected response'
        );
    };
};

done_testing();