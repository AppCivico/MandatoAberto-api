package MandatoAberto::Test::Further;

use common::sense;
use FindBin qw($RealBin);
use Carp;

use Test::More;
use Catalyst::Test q(MandatoAberto);
use CatalystX::Eta::Test::REST;

use Data::Printer;
use JSON::MaybeXS;
use Data::Fake qw(Core Company Dates Internet Names Text);
use MandatoAberto::Utils;

our $votolegal_response;
our $dialogflow_response;

# Ugly hack
sub import {
    strict->import;
    warnings->import;

    no strict 'refs';

    my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if $name eq 'BEGIN';     # don't export BEGIN blocks
        next if $name eq 'import';    # don't export this sub
        next unless *{$symbol}{CODE}; # export subs only

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $obj = CatalystX::Eta::Test::REST->new(
    do_request => sub {
        my $req = shift;

        eval 'do{my $x = $req->as_string; p $x}' if exists $ENV{TRACE} && $ENV{TRACE};
        my ($res, $c) = ctx_request($req);
        eval 'do{my $x = $res->as_string; p $x}' if exists $ENV{TRACE} && $ENV{TRACE};
        return $res;
    },
    decode_response => sub {
        my $res = shift;
        return decode_json($res->content);
    }
);

for (qw/rest_get rest_put rest_head rest_delete rest_post rest_reload rest_reload_list/) {
    eval('sub ' . $_ . ' { return $obj->' . $_ . '(@_) }');
}

sub stash_test ($&) {
    $obj->stash_ctx(@_);
}

sub stash ($) {
    $obj->stash->{$_[0]};
}

sub test_instance {$obj}

sub db_transaction (&) {
    my ($subref, $modelname) = @_;

    my $schema = MandatoAberto->model($modelname || 'DB');

    eval {
        $schema->txn_do(
            sub {
                $subref->($schema);
                die 'rollback';
            }
        );
    };
    die $@ unless $@ =~ /rollback/;
}

my $auth_user = {};

sub api_auth_as {
    my (%conf) = @_;

    if (!exists($conf{user_id})) {
        croak "api_auth_as: missing 'user_id'.";
    }

    my $user_id = $conf{user_id};

    my $schema = MandatoAberto->model(defined($conf{model}) ? $conf{model} : 'DB');

    if ($auth_user->{id} != $user_id) {
        my $user = $schema->resultset("User")->find($user_id);
        croak 'api_auth_as: user not found' unless $user;

        my $session = $user->new_session(ip => "127.0.0.1");

        $auth_user = {
            id      => $user_id,
            api_key => $session->{api_key},
        };
    }

    $obj->fixed_headers([ 'x-api-key' => $auth_user->{api_key} ]);
}

sub create_politician {
    my (%opts) = @_;

    my %params = (
        email            => fake_email()->(),
        password         => 'foobarpass',
        name             => fake_name()->(),
        address_state_id => 26,
        address_city_id  => 9508,
        party_id         => fake_int(1, 35)->(),
        office_id        => fake_int(1, 8)->(),
        gender           => fake_pick(qw/F M/)->(),
        movement_id      => fake_int(1, 7)->(),
        %opts
    );

    return $obj->rest_post(
        '/api/register/politician',
        name                => 'add politician',
        automatic_load_item => 0,
        stash               => "politician",
        [ %params ],
    );
}

sub create_dialog {
    my (%opts) = @_;

    api_auth_as user_id => 1;

    my %params = (
        name        => fake_words(1)->(),
        description => fake_words(1)->(),
        %opts
    );

    return $obj->rest_post(
        "/api/admin/dialog",
        name                => 'add dialog',
        automatic_load_item => 0,
        stash               => "dialog",
        [ %params ]
    );
}

sub create_question {
    my (%opts) = @_;

    api_auth_as user_id => 1;

    my $dialog_id = $opts{dialog_id};

    return $obj->rest_post(
        "/api/admin/dialog/$dialog_id/question",
        name                => 'create question',
        stash               => 'question',
        automatic_load_item => 0,
        params              => {
            name          => fake_words(4)->(),
            content       => fake_words(1)->(),
            citizen_input => fake_words(1)->(),
            %opts
        }
    );
}

sub answer_question {
    my (%opts) = @_;

    my $politician_id = delete $opts{politician_id};
    my $question_id   = delete $opts{question_id};

    api_auth_as user_id => $politician_id;

    return $obj->rest_post(
        "/api/politician/$politician_id/answers",
        name                => 'answer question',
        stash               => 'answer',
        automatic_load_item => 0,
        code                => 200,
        params              => {
            "question[$question_id][answer]" => fake_words(1)->()
        }
    );
}

sub create_recipient {
    my (%opts) = @_;

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    return $obj->rest_post(
        '/api/chatbot/recipient',
        name                => 'create recipient',
        stash               => 'recipient',
        automatic_load_item => 0,
        params              => {
            name           => fake_name()->(),
            fb_id          => fake_words(3)->(),
            origin_dialog  => fake_words(1)->(),
            gender         => fake_pick( qw/ M F/ )->(),
            cellphone      => fake_digits("+551198#######")->(),
            email          => fake_email()->(),
            security_token => $security_token,
            %opts,
        }
    );
}

sub create_issue {
    my (%opts) = @_;

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $fake_entity = encode_json(
		{
			"responseId" => "f51c7faf-7569-425c-898e-f1130f17960b-7e4f1f27",
			"queryResult" => {
				"fulfillmentMessages" => [
					{
						"platform" => "PLATFORM_UNSPECIFIED",
						"text" => {
							"text" => ["Lamento, mas não compreendi."]
						},
						"message" => "text"
					}
				],
				"outputContexts" => [],
				"queryText" => "O que você acha do aborto?",
				"speechRecognitionConfidence" => 0,
				"action" => "input.unknown",
				"parameters" => {
					"fields" => {}
				},
				"allRequiredParamsPresent" => 1,
				"fulfillmentText" => "Lamento, mas não compreendi.",
				"webhookSource" => "",
				"webhookPayload" => undef,
				"intent" => {
					"inputContextNames" => [],
					"events" => [],
					"trainingPhrases" => [],
					"outputContexts" => [],
					"parameters" => [],
					"messages" => [],
					"defaultResponsePlatforms" => [],
					"followupIntentInfo" => [],
					"name" => "projects/dipiou-eivcjk/agent/intents/1f450a68-c73f-4419-8366-3c8b6fb4299a",
					"displayName" => "direitos_animais",
					"priority" => 0,
					"isFallback" => 1,
					"webhookState" => "WEBHOOK_STATE_UNSPECIFIED",
					"action" => "",
					"resetContexts" => 0,
					"rootFollowupIntentName" => "",
					"parentFollowupIntentName" => "",
					"mlDisabled" => 0
				},
				"intentDetectionConfidence" => 1,
				"diagnosticInfo" => undef,
				"languageCode" => "pt-br"
			},
			"webhookStatus" => undef
		}
    );

    return $obj->rest_post(
        '/api/chatbot/issue',
        name                => 'create issue',
        stash               => 'issue',
        automatic_load_item => 0,
        params              => {
            message        => fake_words(4)->(),
            security_token => $security_token,
            entities       => $fake_entity,
            %opts,
        }
    );
}

sub create_knowledge_base {
    my (%opts) = @_;

    my $politician_id = $opts{politician_id};

    return $obj->rest_post(
        "/api/politician/$politician_id/knowledge-base",
        name                => 'create issue',
        stash               => 'issue',
        automatic_load_item => 0,
        params              => {
            answer => fake_words(3)->(),
            type   => fake_pick( qw( posicionamento histórico proposta ) )->(),
            %opts,
        }
    );
}

sub setup_votolegal_integration_success {
    $votolegal_response = {
        id       => fake_int(1, 100)->(),
        username => 'fake_username'
    };
}

sub setup_votolegal_integration_success_with_custom_url {
    $votolegal_response = {
        id         => fake_int(1, 100)->(),
        username   => 'fake_username',
        custom_url => 'https://www.foobar.com.br'
    };
}

sub setup_votolegal_integration_fail {
    $votolegal_response = {
        votolegal_email => 'non existent on voto legal'
    };
}

sub setup_dialogflow_entities_response {
    $dialogflow_response = {
        "entityTypes" => [
            {
                "name" => "projects/mandato-aberto/agent/entityTypes/a0a263e9-41e7-4cf9-9d1a-92919d16788d",
                "displayName" => "Desemprego",
                "kind" => "KIND_MAP",
                "autoExpansionMode" => "AUTO_EXPANSION_MODE_DEFAULT",
                "entities" => [
                    {
                        "value" => "desemprego",
                        "synonyms" => [
                            "desemprego"
                        ]
                    },
                    {
                        "value" => "desempregado",
                        "synonyms" => [
                            "desempregado"
                        ]
                    }
                ]
            },
            {
                "name" => "projects/mandato-aberto/agent/entityTypes/1d139683-fae2-4c1b-ac1b-1077bd4a66d9",
                "displayName" => "Tags",
                "kind" => "KIND_MAP",
                "autoExpansionMode" => "AUTO_EXPANSION_MODE_DEFAULT",
                "entities" => [
                    {
                        "value" => "recessão",
                        "synonyms" => [
                            "recessão"
                        ]
                    },
                    {
                        "value" => "internet",
                        "synonyms" => [
                            "internet",
                            "web"
                        ]
                    },
                    {
                        "value" => "eleitor",
                        "synonyms" => [
                            "eleitor",
                            "eleitorado"
                        ]
                    }
                ]
            },
            {
                "name" => "projects/mandato-aberto/agent/entityTypes/21ef68da-e7ff-4b71-be6e-88335cb6132b",
                "displayName" => "Aborto",
                "kind" => "KIND_MAP",
                "autoExpansionMode" => "AUTO_EXPANSION_MODE_DEFAULT",
                "entities" => [
                    {
                        "value" => "aborto",
                        "synonyms" => [
                            "aborto",
                            "abortu",
                            "abort"
                        ]
                    },
                    {
                        "value" => "interrupção da gravidez",
                        "synonyms" => [
                            "interrupção da gravidez"
                        ]
                    }
                ]
            },
            {
                "name" => "projects/mandato-aberto/agent/entityTypes/21ef68da-e7ff-4b71-be6e-99335cb8243b",
                "displayName" => "default fallback intent",
                "kind" => "KIND_MAP",
                "autoExpansionMode" => "AUTO_EXPANSION_MODE_DEFAULT",
                "entities" => [ ]
            }
        ]
    }
}

sub setup_dialogflow_intents_response {
    $dialogflow_response = {
        "intents" => [
            {
                "name"         => "projects/mandato-aberto/agent/intents/09fe19c6-1dc6-417c-9e2b-a81edd8e1e31",
                "displayName"  => "saude",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/9eca11c4-90d9-4e7a-b199-03030e1f237d",
                "displayName"  => "aborto",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/1dab4a2a-db67-451a-a49b-723c39a3775f",
                "displayName"  => "mobilidade_urbana",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/1dab4a2a-db67-451a-a49b-723c39a3775f",
                "displayName"  => "mobilidade_urbana",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/124566b6-24eb-4663-b697-dd900417c30a",
                "displayName" => "Default Welcome Intent",
                "priority" => 500000,
                "events" => [
                    "WELCOME"
                ],
                "action" => "input.welcome",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Olá!",
                            "Oi!"
                            ]
                        }
                    }
                ]
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/63113792-2fd4-40c6-9bd0-bf4197c60276",
                "displayName" => "Default Fallback Intent",
                "priority" => 500000,
                "isFallback" => \1,
                "action" => "input.unknown",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Lamento, mas não compreendi.",
                            "Desculpe, mas não compreendi.",
                            "Infelizmente, não captei o que deseja.",
                            "Não consegui compreender, desculpe."
                            ]
                        }
                    }
                ]
            }
        ]
    }
}

sub setup_dialogflow_intents_other_project_response {
    $dialogflow_response = {
        "intents" => [
            {
                "name"         => "projects/mandato-aberto/agent/intents/09fe19c6-1dc6-417c-9e2b-a81edd8e1e31",
                "displayName"  => "sobre x",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/09fe19c6-1dc6-417c-9e2b-a81edd8e1e31",
                "displayName"  => "sobre y",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/124566b6-24eb-4663-b697-dd900417c30a",
                "displayName" => "Default Welcome Intent",
                "priority" => 500000,
                "events" => [
                    "WELCOME"
                ],
                "action" => "input.welcome",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Olá!",
                            "Oi!"
                            ]
                        }
                    }
                ]
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/63113792-2fd4-40c6-9bd0-bf4197c60276",
                "displayName" => "Default Fallback Intent",
                "priority" => 500000,
                "isFallback" => \1,
                "action" => "input.unknown",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Lamento, mas não compreendi.",
                            "Desculpe, mas não compreendi.",
                            "Infelizmente, não captei o que deseja.",
                            "Não consegui compreender, desculpe."
                            ]
                        }
                    }
                ]
            }
        ]
    }
}


sub setup_dialogflow_intents_with_one_deleted_response {
    $dialogflow_response = {
        "intents" => [
            {
                "name"         => "projects/mandato-aberto/agent/intents/09fe19c6-1dc6-417c-9e2b-a81edd8e1e31",
                "displayName"  => "saude",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/1dab4a2a-db67-451a-a49b-723c39a3775f",
                "displayName"  => "mobilidade_urbana",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/1dab4a2a-db67-451a-a49b-723c39a3775f",
                "displayName"  => "mobilidade_urbana",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/124566b6-24eb-4663-b697-dd900417c30a",
                "displayName" => "Default Welcome Intent",
                "priority" => 500000,
                "events" => [
                    "WELCOME"
                ],
                "action" => "input.welcome",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Olá!",
                            "Oi!"
                            ]
                        }
                    }
                ]
            },
            {
                "name" => "projects/prep-chatbot/agent/intents/63113792-2fd4-40c6-9bd0-bf4197c60276",
                "displayName" => "Default Fallback Intent",
                "priority" => 500000,
                "isFallback" => \1,
                "action" => "input.unknown",
                "messages" => [
                    {
                        "text" => {
                            "text" => [
                            "Lamento, mas não compreendi.",
                            "Desculpe, mas não compreendi.",
                            "Infelizmente, não captei o que deseja.",
                            "Não consegui compreender, desculpe."
                            ]
                        }
                    }
                ]
            }
        ]
    }
}

sub setup_dialogflow_intents_response_with_skip {
    $dialogflow_response = {
        "intents" => [
            {
                "name"         => "projects/mandato-aberto/agent/intents/09fe19c6-1dc6-417c-9e2b-a81edd8e1e31",
                "displayName"  => "saude",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/9eca11c4-90d9-4e7a-b199-03030e1f237d",
                "displayName"  => "aborto",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
            {
                "name"         => "projects/mandato-aberto/agent/intents/1dab4a2a-db67-451a-a49b-723c39a3775f",
                "displayName"  => "Fallback",
                "priority"     => 500000,
                "webhookState" => "WEBHOOK_STATE_ENABLED"
            },
        ]
      };
}

sub activate_chatbot {
    my ($politician_id) = shift;

    return $obj->rest_put(
        "/api/politician/$politician_id",
        name                => 'edit politician',
        automatic_load_item => 0,
        stash               => "chatbot",
        [
            fb_page_access_token => 'fake_access_token',
            fb_page_id           => 'fake_page_id',
        ],
    );
}

sub create_user {
    my (%opts) = @_;

    my %params = (
        email       => fake_email()->(),
        password    => 'foobarpass',
        name        => fake_name()->(),
        movement_id => fake_int(1, 7)->(),
        %opts
    );

    return $obj->rest_post(
        '/api/register',
        name                => 'create user',
        automatic_load_item => 0,
        stash               => 'user',
        [ %params ],
    );
};

1;

