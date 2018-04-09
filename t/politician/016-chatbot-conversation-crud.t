use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use YAML::XS;
use File::Slurp;

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

    answer_question(
        politician_id => $politician_id,
        question_id   => $question_id
    );

    my $chatbot_conversation_model = read_file("$Bin/../mock/conversation_model.json");
    my $decoded_conversation_model = decode_json($chatbot_conversation_model);

    subtest 'First node' => sub {
        rest_post "/api/politician/$politician_id/chatbot-conversation",
            name    => 'First node is not root',
            is_fail => 1,
            code    => 400,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json(
                {
                    conversation_model => [
                        {
                            name     => 'node_10',
                            messages => [ 'Bem vindo' ],
                            options  => [
                                {
                                    text    => 'Voltar para o início',
                                    payload => 'root'
                                }
                            ]
                        }
                    ]
                }
            ),
        ;

        rest_post "/api/politician/$politician_id/chatbot-conversation",
            name    => 'First node with parent',
            is_fail => 1,
            code    => 400,
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json(
                {
                    conversation_model => [
                        {
                            name     => 'root',
                            parent   => 'node_10',
                            messages => [ 'Bem vindo' ],
                            options  => [
                                {
                                    text    => 'Voltar para o início',
                                    payload => 'root'
                                }
                            ]
                        }
                    ]
                }
            ),
        ;
    };

    rest_post "/api/politician/$politician_id/chatbot-conversation",
        name    => 'Create chatbot conversation model',
        headers => [ 'Content-Type' => 'application/json' ],
        data    => encode_json( { conversation_model => $decoded_conversation_model } ),
    ;
};

done_testing();