use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician    = create_politician( fb_page_id => 'foo', );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    rest_post "/api/chatbot/recipient",
        name    => "create recipient without fb_id",
        is_fail => 1,
        [
            politician_id  => $politician_id,
            origin_dialog  => fake_words(1)->(),
            name           => fake_name()->(),
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/recipient",
        name    => "create recipient without name",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            fb_id         => "foobar",
            politician_id => $politician_id,
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/recipient",
        name    => "email is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            email         => "foobar",
            security_token => $security_token
        ]
    ;

    rest_post "/api/chatbot/recipient",
        name    => "cellphone is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            cellphone     => "foobar",
            security_token => $security_token
        ]
    ;

    my $fb_id     = fake_words(1)->();
    my $cellphone = fake_digits("+551198#######")->();
    my $email     = fake_email()->();
    my $gender    = fake_pick( qw/F M/ )->();

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => $fb_id,
            email         => $email,
            cellphone     => $cellphone,
            gender        => $gender,
            security_token => $security_token
        ]
    ;
    my $citizen_id = stash "c1.id";

    rest_get "/api/chatbot/recipient",
        name    => "search with missing fb_id",
        is_fail => 1,
        code    => 400,
        [ security_token => $security_token ]
    ;

    rest_get "/api/chatbot/recipient",
        name  => "get recipient",
        list  => 1,
        stash => "get_citizen",
        [
            fb_id          => $fb_id,
            security_token => $security_token
        ]
    ;

    stash_test "get_citizen" => sub {
        my $res = shift;

        is($res->{id}, $citizen_id, 'id');
        is($res->{email}, $email, 'email');
        is($res->{cellphone}, $cellphone, 'cellphone');
        is($res->{gender}, $gender, 'gender');
    };

    my $new_email = fake_email()->();
    rest_post "/api/chatbot/recipient/",
        name => "change recipient data",
        [
            fb_id          => $fb_id,
            politician_id  => $politician_id,
            email          => $new_email,
            security_token => $security_token
        ]
    ;

    rest_reload_list "get_citizen";

    stash_test "get_citizen.list" => sub {
        my $res = shift;

        is($res->{id}, $citizen_id, 'id');
        is($res->{email}, $new_email, 'email');
    };

    subtest 'Politician | Create recipient (new model)' => sub {

        rest_post "/api/chatbot/politician/$politician_id/recipient",
            name                => 'create recipient',
            automatic_load_item => 0,
            stash               => 'c10',
            [
                politician_id  => $politician_id,
                name           => fake_name()->(),
                fb_id          => 'fake_fb_id',
                email          => 'fake_email@email.com',
                cellphone      => fake_digits("+551198#######")->(),
                gender         => $gender,
                security_token => $security_token
            ]
        ;
    };

    subtest 'Chatbot | Get all recipients' => sub {

        rest_get "/api/chatbot/recipient/all",
            name  => 'get recipients',
            stash => 'r1',
            [
                organization_chatbot_id => $politician->user->organization_chatbot_id,
                security_token          => $security_token
            ]
        ;

        stash_test 'r1' => sub {
            my $res = shift;

            ok( ref $res->{recipients} eq 'ARRAY', 'recipients is an array' );
            is( scalar @{$res->{recipients}}, 2,   'recipients has two itens' );
        }
    }
};

done_testing();
