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
        $user_id         = create_user(custom_url => 'foobar.com', has_ticket => 1);
        $user_id         = $user_id->{id};
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;
        $chatbot_id      = $schema->resultset('OrganizationChatbot')->search(undef)->next->id;
        $recipient       = $schema->resultset('Recipient')->create(
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
                page_id                 => 'foobar',
                access_token            => 'foobar'
            }
        );

        ok $schema->resultset('PoliticianEntity')
          ->create({name => 'default fallback intent', organization_chatbot_id => $chatbot_id});
    };

    my $ticket_type;
    subtest 'Chatbot | Create ticket' => sub {

        # Listando tipos de ticket
        rest_get "/api/chatbot/ticket/type",
          stash => 'tt1',
          [
            security_token => $security_token,
            chatbot_id     => $chatbot_id,
          ];

        my $ticket_types = stash 'tt1';

        is ref $ticket_types->{ticket_types}, 'ARRAY';
        ok defined $ticket_types->{ticket_types}->[0]->{id};
        ok defined $ticket_types->{ticket_types}->[0]->{name};
        ok defined $ticket_types->{ticket_types}->[0]->{can_be_anonymous};

        ok $ticket_type
          = $schema->resultset('OrganizationTicketType')->search({id => $ticket_types->{ticket_types}->[0]->{id}})
          ->next->update({can_be_anonymous => 1});

        # Criando ticket
        is $email_rs->count, 0;

        my $res = rest_post "/api/chatbot/ticket",
          automatic_load_item => 0,
          params              => [
            security_token      => $security_token,
            type_id             => $ticket_type->id,
            anonymous           => 1,
            chatbot_id          => $chatbot_id,
            fb_id               => 'bar',
            message             => 'Olá, você pode me ajudar?',
            data                => to_json({cpf => '1111111111111', email => 'foobar@email.com'}),
            ticket_attachment_0 => "www.google.com",
            ticket_attachment_1 => "www.google_2.com",
          ],
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
          ];

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
          ];

        # is $email_rs->count, 2;

        $res = rest_put "/api/chatbot/ticket/$ticket_id",
          code   => 200,
          params => [
            security_token      => $security_token,
            status              => 'canceled',
            ticket_attachment_0 => 'www.google.com'
          ],
          files => {
            ticket_attachment_0 => "$Bin/picture_3.jpg",
          };

        # is $email_rs->count, 3;

        # Creating ticket using recipient_id
        $res = rest_post "/api/chatbot/ticket",
          automatic_load_item => 0,
          params              => [
            security_token => $security_token,
            type_id        => $ticket_type->id,
            anonymous      => 1,
            chatbot_id     => $chatbot_id,
            recipient_id   => $recipient_id,
            message        => 'Olá, você pode me ajudar?',
            data           => to_json({cpf => '1111111111111', email => 'foobar@email.com'}),
          ],
          ;

        $res = rest_post "/api/chatbot/ticket",
          is_fail => 1,
          code    => 400,
          params  => [
            security_token => $security_token,
            type_id        => $ticket_type->id,
            anonymous      => 1,
            recipient_id   => $recipient_id,
            message        => 'Olá, você pode me ajudar?',
            data           => to_json({cpf => '1111111111111', email => 'foobar@email.com'}),
          ],
          ;
    };

    subtest 'User | CRUD ticket' => sub {
        api_auth_as user_id => $user_id;

        my $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket";

        is ref $res->{tickets}, 'ARRAY';
        ok defined $res->{tickets}->[0]->{status};
        ok defined $res->{tickets}->[0]->{message};
        ok defined $res->{tickets}->[0]->{created_at};

        ok my $ticket_id = $res->{tickets}->[0]->{id};
        ok my $ticket    = $schema->resultset('Ticket')->find($ticket_id);

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
        $res = rest_get "/api/organization/$organization_id/chatbot/$chatbot_id/ticket", [filter => 'closed'];
        is scalar @{$res->{tickets}}, 0;

        $res = rest_get "/api/politician/$user_id/ticket/types";

        is $res->{itens_count}, 2;

        is ref $res->{ticket_types}, 'ARRAY';
        ok defined $res->{ticket_types}->[0]->{id};
        ok defined $res->{ticket_types}->[0]->{name};
        ok exists $res->{ticket_types}->[0]->{can_be_anonymous};
        ok exists $res->{ticket_types}->[0]->{description};
        ok exists $res->{ticket_types}->[0]->{usual_response_interval};
        ok exists $res->{ticket_types}->[0]->{usual_response_time};

        ok my $ticket_type_id = $res->{ticket_types}->[0]->{id};

        $res = rest_get "/api/politician/$user_id/ticket/types/$ticket_type_id";

        ok defined $res->{id};
        ok defined $res->{name};
        ok exists $res->{can_be_anonymous};
        ok exists $res->{description};
        ok exists $res->{usual_response_interval};
        ok exists $res->{usual_response_time};

        $res = rest_put "/api/politician/$user_id/ticket/types/$ticket_type_id",
          code   => 200,
          params => [
            send_email_to           => 'foobar@email.com',
            usual_response_interval => '10:00:00'
          ];

        $res = rest_get "/api/politician/$user_id/ticket/types/$ticket_type_id";

        ok defined $res->{id};
        ok defined $res->{name};
        ok exists $res->{can_be_anonymous};
        ok exists $res->{description};
        ok exists $res->{usual_response_interval};
        ok exists $res->{usual_response_time};

    };

    subtest 'Web user | CRUD ticket' => sub {
        ok my $web_recipient = $schema->resultset('Recipient')->create(
            {
                name                    => 'foo',
                uuid                    => \'uuid_generate_v4()',
                page_id                 => 'foobar',
                organization_chatbot_id => $chatbot_id
            }
        );
        ok my $web_recipient_id = $web_recipient->id;

        my $res = rest_post "/api/chatbot/ticket",
          automatic_load_item => 0,
          params              => [
            security_token => $security_token,
            type_id        => $ticket_type->id,
            anonymous      => 0,
            chatbot_id     => $chatbot_id,
            recipient_id   => $web_recipient_id,
            message        => 'Olá, você pode me ajudar?',
            data           => to_json({cpf => '1111111111111', mail => 'foobar@email.com'}),
          ],
          ;

        my $ticket_id = $res->{id};

        is $email_rs->count, 5;

        $res = rest_put "/api/organization/$organization_id/chatbot/$chatbot_id/ticket/$ticket_id",
          automatic_load_item => 0,
          code                => 200,
          [
            # assignee_id => $user_id,
            # status      => 'progress',
            response => 'foobar',
          ];

        is $email_rs->count, 6;

    };

};

done_testing();
