use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    api_auth_as user_id => 1;
    rest_post "/api/register/poll",
        name    => "Create poll as an admin",
        is_fail => 1,
        code    => 403
    ;

    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/poll",
        name    => "Poll without name",
        is_fail => 1,
        code    => 400,
        [
            'question[0]'            => 'alalala?',
            'question[0][option][0]' => 'Sim',
            'question[0][option][1]' => 'Não',
            'question[1]'            => 'foobar?',
            'question[1][option][0]' => 'foo',
            'question[1][option][1]' => 'bar',
        ]
    ;

    my $poll_name = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name => $poll_name,
            'questions[0]'            => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'            => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;

    rest_post "/api/register/poll",
       name    => "Poll with repeated name",
       is_fail => 1,
       code    => 400,
       [
            name => $poll_name,
            'question[0]'            => 'alalala?',
            'question[0][option][0]' => 'Sim',
            'question[0][option][1]' => 'Não',
            'question[1]'            => 'foobar?',
            'question[1][option][0]' => 'foo',
            'question[1][option][1]' => 'bar',
       ]
    ;

};

done_testing();