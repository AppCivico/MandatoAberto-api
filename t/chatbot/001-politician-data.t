use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    my $question_id;
    subtest 'Create dialog and questions' => sub {
        api_auth_as user_id => 1;

        create_dialog(name => 'foobar');
        my $dialog_id = stash "dialog.id";

        my $question_name = fake_words(1)->();
        rest_post "/api/admin/dialog/$dialog_id/question",
          name                => "question",
          automatic_load_item => 0,
          stash               => "q1",
          [
            name          => $question_name,
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->()
          ];
        $question_id = stash "q1.id";
    };

    my $party    = fake_int(1, 35)->();
    my $office   = fake_int(1, 8)->();
    my $gender   = fake_pick(qw/F M/)->();
    my $email    = fake_email()->();
    my $password = 'foobar';

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        email                   => $email,
        password                => $password,
        name                    => "Lucas Ansei",
        address_state_id        => 26,
        address_city_id         => 9508,
        party_id                => $party,
        office_id               => $office,
        fb_page_id              => "FOO",
        fb_page_access_token    => "FOOBAR",
        gender                  => $gender,
    );
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset("Politician")->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    ok my $dialog = $schema->resultset('OrganizationDialog')->create(
        {
            organization_id => $politician->user->organization->id,
            name            => 'foobar',
            description     => 'foobar'
        }
    );
    ok my $question = $schema->resultset('OrganizationQuestion')->create(
        {
            organization_dialog_id => $dialog->id,
            name                   => 'foobar',
            content                => fake_words(1)->(),
            citizen_input          => fake_words(1)->()
        }
    );
    $question_id = $question->id;

    my $answer_content = fake_words(1)->();
    subtest 'Politician | Create answer' => sub {

        rest_post "/api/politician/$politician_id/answers",
            name  => "POST politician answer",
            code  => 200,
            stash => "a1",
            [ "question[$question_id][answer]" => $answer_content ]
        ;
    };

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    my $res = rest_get "/api/chatbot/politician",
        name  => "get politician data",
        list  => 1,
        stash => "get_politician_data",
        [
            fb_page_id     => "fake_page_id",
            security_token => $security_token
        ]
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        is ($res->{user_id}, $politician_id, 'user_id');
        is ($res->{name},    "Lucas Ansei",  'name');
    };

    rest_get "/api/chatbot/politician",
        name    => "get politician data with invalid platform",
        is_fail => 1,
        code    => 400,
        [
            platform       => 'FOO',
            security_token => $security_token
        ]
    ;

    rest_get '/api/chatbot/politician',
        name    => 'get politician data with non existent twitter_id',
        is_fail => 1,
        code    => 400,
        [
            platform       => 'twitter',
            twitter_id     => 'foobar',
            security_token => $security_token
        ]
    ;

};

done_testing();
