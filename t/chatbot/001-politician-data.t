use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
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

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    rest_get "/api/chatbot/politician",
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

        is ($res->{user_id},                                     $politician_id,                                                         'user_id');
        is ($res->{name},                                        "Lucas Ansei",                                                          'name');
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
