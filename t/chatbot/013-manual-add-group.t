use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician();
    my $politician    = $schema->resultset('Politician')->find(stash 'politician.id');
    my $politician_id = $politician->id;

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    create_recipient( politician_id => $politician_id );
    my $recipient = $schema->resultset('Recipient')->find(stash 'recipient.id');

    my $group_id;
    subtest 'Creating empty group' => sub {
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            headers => [ 'Content-Type' => 'application/json' ],
            stash   => 'group',
            data    => encode_json({
                name     => 'AppCivico',
                filter   => {},
            }),
        ;

        $group_id = $schema->resultset('Group')->next->id;
    };

    subtest 'Chatbot | Add to group' => sub {
        rest_post "/api/chatbot/politician/$politician_id/group/$group_id/manual-add",
            name => 'add to group',
            code => 200,
            [
                page_id         => 'fake_page_id',
                fb_id           => $recipient->fb_id,
                security_token => $security_token
            ]
        ;
    };
};

done_testing();
