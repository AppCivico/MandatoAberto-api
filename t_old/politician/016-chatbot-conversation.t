use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use YAML::XS;

my $schema = MandatoAberto->model('DB');

db_transaction {
    my $dialog_name = fake_words(2)->();

    create_dialog(
        name => $dialog_name
    );
    my $dialog_id = stash "dialog.id";

    create_question(
        dialog_id => $dialog_id
    );
    my $question_id = stash "question.id";

    create_politician();
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    answer_question(
        politician_id => $politician_id,
        question_id   => $question_id
    );
};

done_testing();
