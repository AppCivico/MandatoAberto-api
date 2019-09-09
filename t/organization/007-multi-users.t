use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use JSON qw(to_json);

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot_id, $recipient_id, $recipient);
    my ($first_user, $second_user);
    subtest 'Create users' => sub {

        $first_user = create_user();
        $first_user = $schema->resultset('User')->find($first_user->{id});

        my $invite_token = $schema->resultset('Organization')->search(undef)->next->invite_token;

        $second_user = create_user(invite_token => $invite_token);
        $second_user = $schema->resultset('User')->find($second_user->{id});

        api_auth_as user_id => $first_user->id;
        activate_chatbot($first_user->id);

        my $chatbot_id = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
        my $recipient  = $schema->resultset('Recipient')->create(
            {
                name                    => 'foo',
                fb_id                   => 'bar',
                page_id                 => 'foobar',
                organization_chatbot_id => $chatbot_id
            }
        );

    };

    subtest 'GET recipients with different logins' => sub {
        my $first_user_id = $first_user->id;

        my $firs_res = rest_get "/api/politician/$first_user_id/recipients",
            name  => 'list recipients',
            stash => 'recipients',
        ;

        my $second_user_id = $second_user->id;
        api_auth_as user_id => $second_user->id;

        my $second_res = rest_get "/api/politician/$second_user_id/recipients",
            name  => 'list recipients',
            stash => 'recipients',
        ;

        is $firs_res->{itens_count}, $second_res->{itens_count};
        is $firs_res->{recipients}->[0]->{id}, $second_res->{recipients}->[0]->{id};
    };

};

done_testing();
