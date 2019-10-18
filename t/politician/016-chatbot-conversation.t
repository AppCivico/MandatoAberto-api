use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use YAML::XS;

my $schema = MandatoAberto->model('DB');

db_transaction {
    my $dialog_name = fake_words(2)->();

    create_politician();
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset('Politician')->find($politician_id);

    ok my $dialog = $schema->resultset('OrganizationDialog')->create(
        {
            organization_id => $politician->user->organization->id,
            name            => 'foobar',
            description     => 'foobar'
        }
    );
    my $dialog_id = $dialog->id;

    ok my $question = $schema->resultset('OrganizationQuestion')->create(
        {
            organization_dialog_id => $dialog->id,
            name                   => fake_words(1)->(),
            content                => fake_words(1)->(),
            citizen_input          => fake_words(1)->()
        }
    );
    my $question_id = $question->id;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    answer_question(
        politician_id => $politician_id,
        question_id   => $question_id
    );
};

done_testing();
