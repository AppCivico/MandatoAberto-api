use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token         = $ENV{CHATBOT_SECURITY_TOKEN};
    my $metrics_security_token = $ENV{METRICS_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot, $chatbot_id);
    my @recipients;
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user();
        $user_id         = $user_id->{id};
        $organization_id = $schema->resultset('Organization')->search(undef)->next->id;

        $chatbot = $schema->resultset('OrganizationChatbot')->search(undef)->next;
        $chatbot_id = $chatbot->id;

        ok $chatbot->organization_chatbot_general_config->update( { dialogflow_config_id => 1 } );

        for (1 .. 10) {
            push @recipients, $schema->resultset('Recipient')->create(
                {
                    name                    => fake_name()->(),
                    fb_id                   => fake_words(2)->(),
                    page_id                 => 'foobar',
                    organization_chatbot_id => $chatbot_id
                }
            );
        }
    };

    my $label;
    subtest 'Create intents and labels' => sub {
        api_auth_as user_id => $user_id;

        setup_dialogflow_intents_response();

        rest_get "/api/politician/$user_id/intent",
            name => 'get intent with sync',
            code => 200,
            [ sync => 1 ]
        ;

        ok $label = $chatbot->labels->create( { name => 'is_target_audience' } );
    };

    my @intents;
    subtest 'Tie recipient to intents and labels' => sub {
        my $intent_rs = $schema->resultset('PoliticianEntity');
        @intents   = $intent_rs->all;

        my $i = 0;
        for my $recipient (@recipients) {
            my @recipient_intents = $recipient->entities || ();

            if ($i < 3) {
                push @recipient_intents, $intents[0]->id;
                push @recipient_intents, $intents[2]->id;

                $intents[0] = $intents[0]->update( { recipient_count => $intents[0]->recipient_count + 1 } );
                $intents[2] = $intents[2]->update( { recipient_count => $intents[2]->recipient_count + 1 } );

                $recipient->recipient_labels->create( { label_id => $label->id } );
            }
            elsif ($i < 7) {
                push @recipient_intents, $intents[0]->id;
                push @recipient_intents, $intents[1]->id;

                $intents[0] = $intents[0]->update( { recipient_count => $intents[0]->recipient_count + 1 } );
                $intents[1] = $intents[1]->update( { recipient_count => $intents[1]->recipient_count + 1 } );
            }
            else {
                push @recipient_intents, $intents[0]->id;
                push @recipient_intents, $intents[3]->id;

                $intents[0] = $intents[0]->update( { recipient_count => $intents[0]->recipient_count + 1 } );
                $intents[3] = $intents[3]->update( { recipient_count => $intents[3]->recipient_count + 1 } );

                $recipient->recipient_labels->create( { label_id => $label->id } );
            }

            ok $recipient->update( { entities => \@recipient_intents } );
            $i++;
        }
    };

    subtest 'Get external metrics' => sub {
        my $res = rest_get "/api/metrics",
            name    => 'missing security_token',
            is_fail => 1,
            code    => 400,
            [ chatbot_id => $chatbot_id ]
        ;

        is $res->{form_error}->{security_token}, 'missing';

        $res = rest_get "/api/metrics",
            name    => 'missing chatbot_id',
            is_fail => 1,
            code    => 400,
            [ security_token => $metrics_security_token ]
        ;

        is $res->{form_error}->{chatbot_id}, 'missing';

        $res = rest_get "/api/metrics",
            name    => 'invalid security_token',
            is_fail => 1,
            code    => 400,
            [
                chatbot_id     => $chatbot_id,
                security_token => 'this is just wrong'
            ]
        ;

        is $res->{form_error}->{security_token}, 'invalid';

        $res = rest_get "/api/metrics",
            name => 'invalid security_token',
            code => 200,
            [
                chatbot_id     => $chatbot_id,
                security_token => $metrics_security_token
            ]
        ;

        is $res->{recipients_with_intent}, 10;
        is $res->{recipients_with_fallback_intent}, 3;

        is ref $res->{most_used_intents}, 'ARRAY';
        is ref $res->{most_used_intents_target_audience}, 'ARRAY';
    };
};

done_testing();
