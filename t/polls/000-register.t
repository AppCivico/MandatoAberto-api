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

    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    api_auth_as user_id => stash "politician.id";
	activate_chatbot($politician_id);

    rest_post "/api/register/poll",
        name    => "Poll without name",
        is_fail => 1,
        code    => 400,
        [
            status_id                  => 1,
            'questions[0]'             => 'alalala?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll without status_id",
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
            status_id                  => 1,
            'questions[0]'             => 1,
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][0]' => 'Não',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with only question",
        is_fail => 1,
        code    => 400,
        [
            name                       => $poll_name,
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with question with only one option",
        is_fail => 1,
        code    => 400,
        [
            name                       => $poll_name,
            status_id                  => 1,
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
            status_id                  => 1,
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
            status_id                  => 1,
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
            status_id                  => 1,
            'questions[0]'             => 'alalala?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
       ]
    ;

    rest_post "/api/register/poll",
        name    => "Poll with only one option",
        is_fail => 1,
        code    => 400,
        [
            name                       => "foobar",
            status_id                  => 2,
            'questions[0]'             => "wololo",
            'questions[0][options][1]' => 'Não',
        ]
    ;

    rest_post "/api/register/poll",
        name    => "Create deactivated poll",
        is_fail => 1,
        [
            name                       => 'this is a deactivated poll',
            status_id                  => 3,
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
        name    => "Create poll with invalid status (non existent id)",
        is_fail => 1,
        [
            name                       => 'this is a poll without a valid status_id',
            status_id                  => fake_int(4, 100)->(),
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
        name    => "Create poll with invalid status (string)",
        is_fail => 1,
        [
            name                       => 'this is a poll without a valid status_id',
            status_id                  => 'foobar',
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
        name                => "Create inactive poll",
        automatic_load_item => 0,
        stash               => "p2",
        [
            name                       => 'this is the second poll',
            status_id                  => 2,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;

    is( $schema->resultset('Poll')->find(stash "p1.id")->status_id, 1, 'first poll is active' );
    is( $schema->resultset('Poll')->find(stash "p2.id")->status_id, 2, 'second poll is inactive' );

    rest_post "/api/register/poll",
        name                => "Create a new active poll",
        automatic_load_item => 0,
        stash               => "p3",
        [
            name                       => 'this is the third poll',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;

    is( $schema->resultset('Poll')->find(stash "p1.id")->status_id, 3, 'first poll is deactivated' );
    is( $schema->resultset('Poll')->find(stash "p2.id")->status_id, 2, 'second poll is inactive' );
    is( $schema->resultset('Poll')->find(stash "p3.id")->status_id, 1, 'third poll is active' );
};

done_testing();