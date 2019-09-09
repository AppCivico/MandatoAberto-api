use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;
use JSON qw(to_json);

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my ($user_id, $organization_id, $chatbot_id, $recipient_id, $recipient);
    subtest 'Create chatbot and recipient' => sub {
        $user_id         = create_user();
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
    };

    my $questionnaire_map_id;
    my $type;
    subtest 'Create questionnaire map' => sub {
        ok my $questionnaire_map = $schema->resultset('QuestionnaireMap')->create(
            {
                type_id => 1,
                map     => to_json(
                    {
                        1 => 'A1',
                        2 => 'A2',
                        3 => 'A3',
                        4 => 'A4'
                    }
                )
            }
        );
        ok $questionnaire_map_id = $questionnaire_map->id;
        ok $type                 = $questionnaire_map->type->name;

        for (1 .. 4) {
            $schema->resultset('QuestionnaireQuestion')->create(
                {
                    code                 => 'A' . $_,
                    questionnaire_map_id => $questionnaire_map->id,
                    text                 => 'foobar' . $_,
                    type                 => 'multiple_choice',
                    multiple_choices  => to_json(
                        {
                            1 => 'foo',
                            2 => 'bar'
                        }
                    )
                }
            )
        }

    };

    subtest 'Chatbot | Pending question' => sub {
        my $res = rest_get '/api/chatbot/questionnaire/pending',
            stash => 'tt1',
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar'
            ];
    };

    subtest 'Chatbot | Answer' => sub {
        my $res = rest_get '/api/chatbot/questionnaire/pending',
            stash => 'tt1',
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar'
            ];

        my $code = $res->{question}->{code};
        $res = rest_post '/api/chatbot/questionnaire/answer',
            automatic_load_item => 0,
            code => 200,
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar',
                code           => $code,
                answer_value   => '1'
            ];

        $res = rest_get '/api/chatbot/questionnaire/pending',
            stash => 'tt1',
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar'
            ];
        $code = $res->{question}->{code};

        $res = rest_post '/api/chatbot/questionnaire/answer',
            automatic_load_item => 0,
            code => 200,
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar',
                code           => $code,
                answer_value   => '1'
            ];

        $res = rest_get '/api/chatbot/questionnaire/pending',
            stash => 'tt1',
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar'
            ];
        $code = $res->{question}->{code};

        $res = rest_post '/api/chatbot/questionnaire/answer',
            automatic_load_item => 0,
            code => 200,
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar',
                code           => $code,
                answer_value   => '1'
            ];

        $res = rest_get '/api/chatbot/questionnaire/pending',
            stash => 'tt1',
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar'
            ];
        $code = $res->{question}->{code};

        $res = rest_post '/api/chatbot/questionnaire/answer',
            automatic_load_item => 0,
            code => 200,
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar',
                code           => $code,
                answer_value   => '1'
            ];

        $res = rest_post '/api/chatbot/questionnaire/reset',
            automatic_load_item => 0,
            code => 200,
            [
                security_token => $security_token,
                type           => $type,
                fb_id          => 'bar',
            ];
    };

};

done_testing();
