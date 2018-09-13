#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use Furl;
use JSON::MaybeXS;

use MandatoAberto::SchemaConnected;

my $schema = get_schema;

my $furl = Furl->new();

my $politician_rs = $schema->resultset('Politician')->with_active_fb_page;

while ( my $politician = $politician_rs->next() ) {
    my $access_token = $politician->fb_page_access_token;

    print STDERR "\npolitician_id: " . $politician->id . "\n";

    my $url = "https://graph.facebook.com/v2.6/me/messenger_profile?access_token=$access_token";

	my $res = $furl->post(
		$url,
		[ 'Content-Type' => "application/json" ],
		encode_json {
			get_started => {
				payload => 'greetings'
			},
			persistent_menu => [
				{
					locale                  => 'default',
					composer_input_disabled => 'false',
					call_to_actions         => [
						{
							title   => "Ir para o início",
							type    => 'postback',
							payload => 'greetings'
						},
						{
							title   => "Desativar notificações",
							type    => 'postback',
							payload => 'add_blacklist'
						},
						{
							title   => "Ativar notificações",
							type    => 'postback',
							payload => 'remove_blacklist'
						}
					]
				}
			]
		}
	);

    die $res->decoded_content unless $res->is_success;
}

1;