use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_dialog(
        name => "Dialogo foo"
    );
    my $first_dialog_id = stash "dialog.id";

    create_dialog(
        name => "Dialogo bar"
    );
    my $second_dialog_id = stash "dialog.id";

    rest_get "/api/dialog/",
        name  => "get dialog",
        list  => 1,
        stash => "get_dialog",
    ;

    stash_test "get_dialog" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                dialog => [
                    {
                        id   => $first_dialog_id,
                        name => "Dialogo foo"
                    },
                    {
                        id   => $second_dialog_id,
                        name => "Dialogo bar"
                    }
                ]
            },
            'get_dialog expected response'
        );
    };

    rest_put "/api/dialog/$first_dialog_id",
        name    => "PUT first dialog with same name",
        is_fail => 1,
        code    => 400,
        [name => "Dialogo foo"]
    ;

    rest_put "/api/dialog/$second_dialog_id",
        name => "PUT second dialog with same name",
        is_fail => 1,
        code    => 400,
        [name => "Dialogo bar"]
    ;

    rest_put "/api/dialog/$first_dialog_id",
        name => "PUT first dialog",
        [name => "foobar"]
    ;

    rest_put "/api/dialog/$second_dialog_id",
        name => "PUT second dialog",
        [name => "FOOBAR"]
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
                dialog => [
                    {
                        id   => $first_dialog_id,
                        name => "foobar"
                    },
                    {
                        id   => $second_dialog_id,
                        name => "FOOBAR"
                    }
                ]
            },
            'get_updated_dialog expected response'
        );
    };
};

done_testing();