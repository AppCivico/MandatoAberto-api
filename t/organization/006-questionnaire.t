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
                        4 => 'A4',
                        5 => 'A5',
                        6 => 'A6',
                        7 => 'A7',
                        8 => 'A8',
                        9 => 'A9',
                        10 => 'A10'
                    }
                )
            }
        );
        ok $questionnaire_map_id = $questionnaire_map->id;
        ok $type                 = $questionnaire_map->type->name;

        for (1 .. 10) {
            my $rules;
            if ($_ == 1) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Muito bom! Mas, essa foi fácil só para começar 😏."
       },
       {
         "conditions": [2],
         "text": "LGPD é Lei Geral de Proteção de Dados. Assista esse vídeo rapidinho sobre o assunto. https://www.youtube.com/watch?v=duLAb-PQuMw"
       },
       {
         "conditions": [3],
         "text": "Que bom que me perguntou 🤓. LGPD é a sigla da Lei Geral de Proteção de Dados. Assista esse vídeo rapidinho sobre o assunto. https://www.youtube.com/watch?v=duLAb-PQuMw"
       }
    ],
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 2) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Indeferido! 👩‍⚖️ A lei é para dar transparência no uso dos dados pessoais. Será que você está atento?"
       },
       {
         "conditions": [2],
         "text": "Deferido! 👩‍⚖️ Vamos testar mais o seu conhecimento!"
       },
       {
         "conditions": [3],
         "text": "Não tem problema, estou aqui para te explicar. A LGPD serve para garantir transparência no uso dos dados das pessoas físicas."
       }
    ],
    "multiple_choice_score_map": {
        "1": 0,
        "2": 1,
        "3": 0
    }
}';
            }
            elsif ($_ == 3) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Tudo bem, eu posso te explicar.👩‍🏫 Dado pessoal qualquer informação relacionada à pessoa, que ela possa ser identificada."
       },
       {
         "conditions": [2],
         "text": "Você está atento, parabéns! 🙂"
       },
       {
         "conditions": [3],
         "text": "Incorreto, dado pessoal qualquer informação relacionada à pessoa, que ela possa ser identificada. 😕"
       }
    ],
    "multiple_choice_score_map": {
        "1": 0,
        "2": 1,
        "3": 0
    }
}';
            }
            elsif ($_ == 4) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Acho que temos um especialista aqui! 😃"
       },
       {
         "conditions": [2],
         "text": "Eu lembro! 🕵️‍♀️ Dados sensíveis são sobre origem racial ou étnica, convicções religiosas, opiniões políticas, informações genéticas ou biométricas, entre outros pontos."
       },
       {
         "conditions": [3],
         "text": "Não é bem assim 🚫 Dados sensíveis são sobre origem racial ou étnica, convicções religiosas, opiniões políticas, informações genéticas ou biométricas, entre outros pontos."
       }
    ],
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 5) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Isso aí! Você está conectado na LGPD.👏👏👏"
       },
       {
         "conditions": [2],
         "text": "Humm, resposta errada. Consentimento é quando o titular concorda com o tratamento de seus dados. ☹️"
       },
       {
         "conditions": [3],
         "text": "Vamos lá! Consentimento é quando o titular concorda com o tratamento de seus dados pessoais para uma finalidade determinada.😉"
       }
    ],
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 6) {
                $rules = '{
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 7) {
                $rules = '{
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 8) {
                $rules = '{
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 9) {
                $rules = '{
    "multiple_choice_score_map": {
        "1": 1,
        "2": 0,
        "3": 0
    }
}';
            }
            elsif ($_ == 10) {
                $rules = '{
    "followup_messages": [
       {
         "conditions": [1],
         "text": "Opa, não é isso não. ANPD é Agência Nacional de Proteção de Dados é órgão responsável pela aplicação da LGPD. Quer entender melhor? Escute aqui: https://www.youtube.com/watch?v=ByhG3E8ltsE"
       },
       {
         "conditions": [2],
         "text": "Perfeito! Resposta correta! 👏👏👏"
       },
       {
         "conditions": [3],
         "text": "Claro! ANPD é Agência Nacional de Proteção de Dados é órgão responsável pela aplicação da LGPD. Quer entender melhor? Escute aqui: https://www.youtube.com/watch?v=ByhG3E8ltsE"
       }
    ],
    "multiple_choice_score_map": {
        "1": 0,
        "2": 1,
        "3": 0
    }
}';
            }

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
                    ),
                    rules => $rules
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
                answer_value   => '2'
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
                answer_value   => '3'
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
                answer_value   => '2'
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
                answer_value   => '2'
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
                answer_value   => '2'
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
                answer_value   => '2'
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
                answer_value   => '2'
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
                answer_value   => '2'
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
