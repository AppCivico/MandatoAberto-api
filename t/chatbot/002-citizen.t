use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/citizen",
        name    => "create citizen without fb_id",
        is_fail => 1,
        [
            politician_id => $politician_id,
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->()
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name    => "create citizen without name",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            fb_id         => "foobar",
            politician_id => $politician_id,
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name    => "create citizen without origin_dialog",
        is_fail => 1,
        [
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar"
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name    => "email is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            email         => "foobar"
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name    => "cellphone is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            cellphone     => "foobar"
        ]
    ;

    rest_post "/api/chatbot/citizen",
        name    => "gender is not required but must be valid",
        is_fail => 1,
        [
            origin_dialog => fake_words(1)->(),
            name          => fake_name()->(),
            politician_id => $politician_id,
            fb_id         => "foobar",
            gender        => "foobar"
        ]
    ;

    my $fb_id     = fake_words(1)->();
    my $cellphone = fake_digits("+551198#######")->();
    my $email     = fake_email()->();
    my $gender    = fake_pick( qw/F M/ )->();

    rest_post "/api/chatbot/citizen",
        name                => "create citizen",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => $fb_id,
            email         => $email,
            cellphone     => $cellphone,
            gender        => $gender
        ]
    ;
    my $citizen_id = stash "c1.id";

    rest_get "/api/chatbot/citizen",
        name    => "search with missing fb_id",
        is_fail => 1,
        code    => 400,
    ;

    rest_get "/api/chatbot/citizen",
        name  => "get citizen",
        list  => 1,
        stash => "get_citizen",
        [ fb_id => $fb_id ]
    ;

    stash_test "get_citizen" => sub {
        my $res = shift;

        is($res->{id}, $citizen_id, 'id');
        is($res->{email}, $email, 'email');
        is($res->{cellphone}, $cellphone, 'cellphone');
        is($res->{gender}, $gender, 'gender');
    };

    my $new_email = fake_email()->();
    rest_post "/api/chatbot/citizen/",
        name => "change citizen data",
        [
            fb_id => $fb_id,
            politician_id => $politician_id,
            email => $new_email
        ]
    ;

    rest_reload_list "get_citizen";

    stash_test "get_citizen.list" => sub {
        my $res = shift;

        is($res->{id}, $citizen_id, 'id');
        is($res->{email}, $new_email, 'email');
    };
};

done_testing();