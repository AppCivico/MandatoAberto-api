use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {

    rest_get "/api/movement",
        name  => 'list movements',
        stash => 'm1'
    ;

    stash_test "m1" => sub {
        my $res = shift;

        ok ( ref $res->{movements} eq 'ARRAY', 'return is an array' );
        is ( exists $res->{movements}->[0]->{id},   1, 'id');
        is ( exists $res->{movements}->[0]->{name}, 1, 'name');
    }
};

done_testing();