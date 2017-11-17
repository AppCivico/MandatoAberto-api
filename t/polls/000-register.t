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
            'questions[0]'             => 'alalala?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll without active boolean",
        is_fail => 1,
        code    => 400,
        [
            name                       => 'foobar',
            'questions[0]'             => 'alalala?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
        ]
    ;

    my $poll_name = fake_words(1)->();

    rest_post "/api/register/poll",
        name    => "Poll with invalid question format",
        is_fail => 1,
        code    => 400,
        [
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 1,
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][0]' => 'Não',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with question with only one option",
        is_fail => 1,
        code    => 400,
        [
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 'foobar',
            'questions[0][options][0]' => 'Sim',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with option with more than 20 characters",
        is_fail => 1,
        code    => 400,
        [
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 'foobar',
            'questions[0][options][0]' => 'This is a string with more than 20 chars',
        ]
    ;


    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
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
            name                       => $poll_name,
            active                     => 1,
            'questions[0]'             => 'alalala?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
       ]
    ;

};

done_testing();