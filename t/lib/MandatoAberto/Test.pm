package MandatoAberto::Test;
use Test::More;
use Test::Mojo;

use Data::Fake qw/ Core Company Dates Internet Names Text /;
use Data::Printer;
use MandatoAberto::Utils;

our $votolegal_response;
our $dialogflow_response;

sub import {
    strict->import;
    warnings->import;

    no strict 'refs';

    my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if $name eq 'BEGIN';
        next if $name eq 'import';
        next unless *{$symbol}{CODE};

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
};

my $t = Test::Mojo->new('MandatoAberto');

sub test_instance { $t }

sub app { $t->app }

sub get_schema { $t->app->schema }

sub db_transaction (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(sub {
            $code->();
            die 'rollback';
        });
    };
    die $@ unless $@ =~ m{rollback};
};

sub api_auth_as {
    my (%args) = @_;

    if (exists $args{user_id}) {
        my $user_id = $args{user_id};

        my $schema = get_schema;
        my $user = $schema->resultset('User')->find($user_id);

        my $user_session = $user->new_session();

        $t->ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->header('X-API-Key' => $user_session->{api_key});
        });
    }
    elsif (exists $args{nobody}) {
        $t->ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->remove('X-API-Key');
        });
    }
    else {
        die __PACKAGE__ . ": invalid params for 'api_auth_as'";
    }

    return $user_session;
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

    $t->post_ok(
        '/api/register/politician',
        form => {
            name                => 'add politician',
            automatic_load_item => 0,
            stash               => "politician",
            %params,
        },
    )
    ->status_is(201)
    ->json_has('/id');

    return $t->tx->res->json;
}

sub create_dialog {
    my (%opts) = @_;

    $t->post_ok(
        '/api/admin/dialog',
        form => {
            name        => fake_words(1)->(),
            description => fake_words(1)->(),
            %opts
        }
    )
    ->status_is(201)
    ;#->header_like(Location => qr{/api/admin/dialog/[0-9]+$});

    return $t->tx->res->json;
}

sub create_recipient {
    my (%opts) = @_;

    my $security_token = env('CHATBOT_SECURITY_TOKEN');

    $t->post_ok(
        '/api/chatbot/recipient',
        form => {
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
    return $t->tx->res->json->{id};
}

sub answer_question {
	my (%opts) = @_;

	my $politician_id = delete $opts{politician_id};
	my $question_id   = delete $opts{question_id};

	api_auth_as user_id => $politician_id;

	$t->post_ok(
		"/api/politician/$politician_id/answers",
		form => {
			"question[$question_id][answer]" => fake_words(1)->(),
            %opts
        }
	);

    return $t->tx->res->json->{id};
}

sub create_issue {
	my (%opts) = @_;

	my $security_token = env('CHATBOT_SECURITY_TOKEN');

	my $fake_entity = encode_json(
		{
			id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
			timestamp => '2018-09-19T21 => 39 => 43.452Z',
			lang      => 'pt-br',
			result    => {
				source           => 'agent',
				resolvedQuery    => 'O que você já fez pelos direitos animais??',
				action           => '',
				actionIncomplete => 0,
				parameters       => {},
				contexts         => [],
				metadata         => {
					intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
					webhookUsed               => 0,
					webhookForSlotFillingUsed => 0,
					isFallbackIntent          => 0,
					intentName                => 'direitos_animais'
				},
				fulfillment => { speech =>  '', messages =>  [] },
				score       => 1
			},
			status    => { code =>  200, errorType =>  'success' },
			sessionId => '1938538852857638'
		}
	);

	$t->post_ok(
		'/api/chatbot/issue',
		form => {
			message        => fake_words(4)->(),
			security_token => $security_token,
			entities       => $fake_entity,
			%opts,
		}
	);

    return $t->tx->res->json->{id};
}


sub create_knowledge_base {
	my (%opts) = @_;

	my $politician_id = $opts{politician_id};

	$t->post_ok(
		"/api/politician/$politician_id/knowledge-base",
		form => {
			answer => fake_words(3)->(),
			type   => fake_pick(qw( posicionamento histórico proposta ))->(),
			%opts,
		}
	);

	return $t->tx->res->json->{id};
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
	$votolegal_response = {votolegal_email => 'non existent on voto legal'};
}


1;

