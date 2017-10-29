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
        [ name => 'Test dialog' ]
    ;

    my $dialog                 = stash "dialog";
    my $first_question_name    = fake_words(2)->();
    my $first_question_content = fake_sentences(1)->();

    rest_post "/api/register/question",
        name                => "Create a question",
        automatic_load_item => 0,
        stash               => "first_question",
        [
            name      => $first_question_name,
            content   => $first_question_content,
            dialog_id => $dialog->{id}
        ]
    ;

    my $second_question_name    = fake_words(2)->();
    my $second_question_content = fake_sentences(1)->();

    rest_post "/api/register/question",
        name                => "Create another question",
        automatic_load_item => 0,
        stash               => "second_question",
        [
            name      => $second_question_name,
            content   => $second_question_content,
            dialog_id => $dialog->{id}
        ]
    ;

    my $first_question_id  = stash "first_question.id";
    my $second_question_id = stash "second_question.id";

    rest_get "/api/question/",
        name  => "get questions",
        list  => 1,
        stash => "get_question",
    ;

    stash_test "get_question" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                questions => [
                    {
                        id      => $first_question_id,
                        name    => $first_question_name,
                        content => $first_question_content,
                        dialog  => {
                            id   => $dialog->{id},
                            name => $dialog->{name}
                        }
                    },
                    {
                        id      => $second_question_id,
                        name    => $second_question_name,
                        content => $second_question_content,
                        dialog  => {
                            id   => $dialog->{id},
                            name => $dialog->{name}
                        }
                    }
                ]
            },
            'get_question expected response');
    };

    rest_put "/api/question/$first_question_id",
        name => "PUT first question",
        stash => "test",
        [
            name    => "Foo",
            content => "Bar"
        ]
    ;

    rest_reload_list "get_question";

    stash_test "get_question.list" => sub {
        my $res = shift;

        is_deeply(
            $res,
            {
                questions => [
                    {
                        id      => $second_question_id,
                        name    => $second_question_name,
                        content => $second_question_content,
                        dialog  => {
                            id   => $dialog->{id},
                            name => $dialog->{name}
                        }
                    },
                    {
                        id      => $first_question_id,
                        name    => "Foo",
                        content => "Bar",
                        dialog  => {
                            id   => $dialog->{id},
                            name => $dialog->{name}
                        }
                    },
                ]
            },
            'get_question expected response');
    };
};

done_testing();