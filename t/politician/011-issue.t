use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $page_id = fake_words(1)->();

    create_politician(
        fb_page_id => $page_id 
    );
    my $politician_id = stash "politician.id";

    my $recipient_fb_id = fake_words(1)->();
    rest_post "/api/chatbot/citizen",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'c1',
        [
            origin_dialog => fake_words(1)->(),
            politician_id => $politician_id,
            name          => fake_name()->(),
            fb_id         => $recipient_fb_id,
            email         => fake_email()->(),
            cellphone     => fake_digits("+551198#######")->(),
            gender        => fake_pick( qw/F M/ )->()
        ]
    ;

    
};

done_testing();