use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model('DB');

db_transaction {
    # Criando 2 diálogos com uma pergunta cada
    my $first_dialog_name = fake_words(2)->();

    create_dialog(
        name => $first_dialog_name
    );
    my $first_dialog_id = stash "dialog.id";

    create_question(
        dialog_id => $first_dialog_id
    );
    my $first_question_id = stash "question.id";

    my $second_dialog_name = fake_words(2)->();

    create_dialog(
        name => $second_dialog_name
    );
    my $second_dialog_id = stash "dialog.id";

    create_question(
        dialog_id => $second_dialog_id
    );
    my $second_question_id = stash "question.id";

    create_politician();
    my $politician_id = stash "politician.id";

    rest_get "/api/politician/$politician_id/available-dialogs",
        name  => 'get available dialogs',
        list  => 1,
        stash => "get_available_dialogs"
    ;

    stash_test "get_available_dialogs" => sub {
        my $res = shift;

        is ($res->{available_dialogs}->[0], undef, 'no available dialogs');
    };

    # Respondendo todos os diálogos
    answer_question(
        politician_id => $politician_id,
        question_id   => $first_question_id
    );

    answer_question(
        politician_id => $politician_id,
        question_id   => $second_question_id
    );

    rest_reload_list "get_available_dialogs";

    stash_test "get_available_dialogs.list" => sub {
        my $res = shift;

        my $first_dialog  = $res->{available_dialogs}->[0];
        my $second_dialog = $res->{available_dialogs}->[1];

        is ($first_dialog->{id},    $first_dialog_id,   'first dialog id');
        is ($first_dialog->{name},  $first_dialog_name, 'first dialog name');

        is ($second_dialog->{id},   $second_dialog_id,   'second dialog id');
        is ($second_dialog->{name}, $second_dialog_name, 'second dialog name');
    };
};

done_testing();