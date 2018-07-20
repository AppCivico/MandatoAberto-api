use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
        fb_page_id => 'foo',
    );
    my $politician_id = stash "politician.id";

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

    rest_post "/api/chatbot/recipient",
        name    => "gender is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            gender        => "foobar",
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

    # TODO testar criação de recipient twitter
};

done_testing();
