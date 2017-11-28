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

    # Criando uma pergunta
    rest_post "/api/dialog/$dialog_id/question",
        name                => "Sucessful question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name          => 'foo',
            content       => "Foobar",
            citizen_input => fake_words(1)->()
        ]
    ;
    my $question_id = stash "q1.id";

    my $question = $schema->resultset("Question")->find($question_id);

    # Criando um representante público e uma resposta para a pergunta
    create_politician;
    my $politician_id = stash "politician.id";
    api_auth_as user_id => $politician_id;

    rest_post "/api/politician/$politician_id/answers",
        name  => "Politician answer",
        code  => 200,
        stash => "a1",
        [ "question[$question_id][answer]" => fake_words(1)->() ]
    ;

    my $answer = stash "a1";

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
                        questions => [
                            {
                                id            => $question_id,
                                name          => $question->get_column('name'),
                                citizen_input => $question->get_column('citizen_input'),
                                content       => $question->get_column('content'),

                                answer => {
                                    content => $answer->{answers}->[0]->{content},
                                    id      => $answer->{answers}->[0]->{id}
                                }
                            }
                        ]
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
                        questions => [
                            {
                                id            => $question_id,
                                name          => $question->get_column('name'),
                                citizen_input => $question->get_column('citizen_input'),
                                content       => $question->get_column('content'),

                                answer => {
                                    content => $answer->{answers}->[0]->{content},
                                    id      => $answer->{answers}->[0]->{id}
                                }
                            }
                        ]
                    },
                ]
            },
            'get_updated_dialog expected response'
        );
    };

    create_politician;
    my $second_politician_id = stash "politician.id";
    api_auth_as user_id => $second_politician_id;

    rest_post "/api/politician/$second_politician_id/answers",
        name  => "Answer for same question",
        code  => 200,
        stash => "a2",
        [ "question[$question_id]" => fake_words(2)->() ]
    ;

    my $second_politician_answer = stash "a2";

    rest_get "/api/dialog/",
        name  => "get dialog",
        list  => 1,
        stash => "get_dialog",
    ;
};

done_testing();