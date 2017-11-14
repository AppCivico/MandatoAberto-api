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

    # rest_post "/api/register/poll",
    #     name    => "Poll without name",
    #     is_fail => 1,
    #     code    => 400
    # ;

    my $poll_name = fake_words(1)->();

    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name => $poll_name,
            'question[0][content]'            => 'alalala?',
            'question[0][option][0][content]' => 'Sim',
            'question[0][option][1][content]' => 'Não',
            'question[1][content]'            => 'foobar?',
            'question[1][option][0][content]' => 'foo',
            'question[1][option][1][content]' => 'bar',
        ]
    ;

    #rest_post "/api/register/poll",
    #    name    => "Poll with repeated name",
    #    is_fail => 1,
    #    code    => 400,
    #    [
    #        name => $poll_name,
    #    ]
    #;

    use DDP;
    my $v = $schema->resultset('PollQuestion')->search(
        { poll_id => stash "p1.id" }
    )->count; p $v;

    p $schema->resultset('QuestionOption')->search(
        undef,
    )->count;

};

done_testing();