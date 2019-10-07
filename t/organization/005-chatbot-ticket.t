use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use JSON;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $email_rs = $schema->resultset('EmailQueue');

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot_id, $recipient_id, $recipient);
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user(custom_url => 'foobar.com');
        $user_id         = $user_id->{id};
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
        $recipient    = $schema->resultset('Recipient')->create(
            {
                name                    => 'foo',
                fb_id                   => 'bar',
                page_id                 => 'foobar',
                organization_chatbot_id => $chatbot_id
            }
        );
        $recipient_id = $recipient->id;

        $schema->resultset('OrganizationChatbotFacebookConfig')->create(
            {
                organization_chatbot_id => $chatbot_id,
                page_id => 'foobar',
                access_token => 'foobar'
            }
        )
    };

    subtest 'Chatbot | Create ticket' => sub {
        # Listando tipos de ticket
        rest_get "/api/chatbot/ticket/type",
            stash => 'tt1',
            [ security_token => $security_token ];

        my $ticket_types = stash 'tt1';

        is ref $ticket_types->{ticket_types}, 'ARRAY';
        ok defined $ticket_types->{ticket_types}->[0]->{id};
        ok defined $ticket_types->{ticket_types}->[0]->{name};

        # Criando ticket
        is $email_rs->count, 0;

        my $res = rest_post "/api/chatbot/ticket",
            automatic_load_item => 0,
            [
                security_token => $security_token,
                type_id        => 1,
                chatbot_id     => $chatbot_id,
                fb_id          => 'bar',
                message        => 'Olá, você pode me ajudar?',
                data        => to_json( { cpf => '1111111111111', email => 'foobar@email.com' } )
            ]
        ;

        # is $email_rs->count, 1; # email created
        ok defined $res->{id};

        ok my $ticket = $schema->resultset('Ticket')->find($res->{id});
        is $ticket->status, 'pending';
        is ref $ticket->message, 'ARRAY';

        $res = rest_get "/api/chatbot/ticket",
            automatic_load_item => 0,
            [
                security_token => $security_token,
                fb_id          => 'bar',
            ]
        ;

        is ref $res->{tickets}, 'ARRAY';
        ok exists $res->{tickets}->[0]->{id};
        ok exists $res->{tickets}->[0]->{closed_at};
        ok exists $res->{tickets}->[0]->{message};
        ok exists $res->{tickets}->[0]->{created_at};
        ok exists $res->{tickets}->[0]->{status};
        ok exists $res->{tickets}->[0]->{response};

        my $ticket_id = $res->{tickets}->[0]->{id};
        $res = rest_put "/api/chatbot/ticket/$ticket_id",
            code => 200,
            [
                security_token => $security_token,
                message        => 'new message',
            ]
        ;
        # is $email_rs->count, 2;

        $res = rest_put "/api/chatbot/ticket/$ticket_id",
            code => 200,
            [
                security_token => $security_token,
                status         => 'canceled',
            ]
        ;
		# is $email_rs->count, 3;
    };

    subtest 'User | CRUD ticket' => sub {
        api_auth_as user_id => $user_id;

        my $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket";

        is ref $res->{tickets}, 'ARRAY';
        ok defined $res->{tickets}->[0]->{status};
        ok defined $res->{tickets}->[0]->{message};
        ok defined $res->{tickets}->[0]->{created_at};

        ok my $ticket_id = $res->{tickets}->[0]->{id};
        ok my $ticket = $schema->resultset('Ticket')->find($ticket_id);

        $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket/$ticket_id";
        $res = rest_put "/api/organization/$organization_id/chatbot/$chatbot_id/ticket/$ticket_id",
            automatic_load_item => 0,
            code                => 200,
            [
                assignee_id => $user_id,
                status      => 'progress',
                response    => 'foobar',
            ];

        ok $ticket->discard_changes;

        $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket/$ticket_id";

        $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket", [ filter => 'closed' ];
        is scalar @{ $res->{tickets} }, 0;
    };

};

done_testing();
