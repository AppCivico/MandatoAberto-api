use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    my $name          = fake_name()->();
    my $origin_dialog = fake_words(1)->();
    my $email         = fake_email()->();
    my $cellphone     = fake_digits("+551198#######")->();
    my $gender        = fake_pick( qw/M F/ )->();

    rest_post "/api/chatbot/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        [
            name          => $name,
            politician_id => $politician_id,
            fb_id         => "foobar",
            origin_dialog => $origin_dialog,
            gender        => $gender,
            cellphone     => $cellphone,
            email         => $email
        ]
    ;

    api_auth_as user_id => $politician_id;

    rest_get "/api/politician/$politician_id/citizen",
        name  => "get citizens",
        list  => 1,
        stash => "get_citizens"
    ;

    stash_test "get_citizens" => sub {
        my $res = shift;

        is ($res->{citizens}->[0]->{name}, $name, 'citizen name');
        is ($res->{citizens}->[0]->{origin_dialog}, $origin_dialog, 'citizen origin_dialog');
        is ($res->{citizens}->[0]->{email}, $email, 'citizen email');
        is ($res->{citizens}->[0]->{cellphone}, $cellphone, 'citizen cellphone');
        is ($res->{citizens}->[0]->{gender}, $gender, 'citizen gender');
    };
};

done_testing();