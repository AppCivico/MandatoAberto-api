use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    create_recipient(
        politician_id => $politician_id
    );
    my $recipient_id = stash "recipient.id";
    my $recipient    = $schema->resultset("Recipient")->find($recipient_id);

    api_auth_as "user_id" => $politician_id;

    my $group = $schema->resultset("Group")->create(
        {
            politician_id    => $politician_id,
            name             => 'foobar',
            filter           => '{}',
            status           => 'ready',
            recipients_count => 0
        }
    );
    my $group_id = $group->id;

    is ($group->recipients_count, 0, 'no recipients on group');

    rest_post "/api/politician/$politician_id/recipients/$recipient_id/group",
        name    => "post to recipient group without group array",
        is_fail => 1,
        code    => 400
    ;

    rest_post "/api/politician/$politician_id/recipients/$recipient_id/group",
        name => "adding recipient to group",
        code => 200,
        [ groups => "[$group_id]" ]
    ;
    is ($group->discard_changes->recipients_count, 1, 'one recipient on group');

};

done_testing();