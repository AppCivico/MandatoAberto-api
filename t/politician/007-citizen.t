use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    my $citizen_name = fake_name()->();

    rest_post "/api/politician/$politician_id/citizen",
        name                => "Create citizen",
        automatic_load_item => 0,
        code                => 200,
        stash               => "c1",
        [
            name          => $citizen_name,
            fb_id         => "foobar",
            origin_dialog => "enquete"
        ]
    ;
    my $citizen    = stash "c1";
    my $citizen_id = $citizen->{id};

    rest_get "/api/politician/$politician_id/citizen",
        name  => "get citizen",
        list  => 1,
        stash => "get_citizen"
    ;

    stash_test "get_citizen" => sub {
        my $res = shift;

        is ($res->{citizens}->[0]->{id}, $citizen_id, 'citizen id');
        is ($res->{citizens}->[0]->{name}, $citizen_name, 'citizen name');
        is ($res->{citizens}->[0]->{gender}, undef, 'citizen gender');
        is ($res->{citizens}->[0]->{origin_dialog}, "enquete", 'citizen origin dialog');
        is ($res->{citizens}->[0]->{fb_id}, "foobar", 'citizen fb_id');
    };
};

done_testing();