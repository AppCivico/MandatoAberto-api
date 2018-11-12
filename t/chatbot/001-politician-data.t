use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t      = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $party    = fake_int(1, 35)->();
    my $office   = fake_int(1, 8)->();
    my $gender   = fake_pick(qw/F M/)->();
    my $email    = fake_email()->();
    my $password = 'foobar';

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $politician = create_politician(
        email                   => $email,
        password                => $password,
        name                    => "Lucas Ansei",
        address_state_id        => 26,
        address_city_id         => 9508,
        party_id                => $party,
        office_id               => $office,
        fb_page_id              => "FOO",
        fb_page_access_token    => "FOOBAR",
        gender                  => $gender,
    );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset("Politician")->find($politician_id);

    api_auth_as user_id => $politician_id;

    subtest 'Politician | Setup voto legal integration' => sub {
        &setup_votolegal_integration_success;

        $t->post_ok(
            "/api/politician/$politician_id/votolegal-integration",
            form => { votolegal_email => 'foobar@email.com' }
        )
        ->status_is(201);
    };

    subtest 'Politician | Setup required data' => sub {
        $schema->resultset("PoliticianContact")->create({
            politician_id => $politician_id,
            twitter       => '@foobar',
            url           => "https://www.google.com",
            email         => $email
        });

        $schema->resultset("PoliticianGreeting")->create({
            politician_id => $politician_id,
            on_facebook   => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
            on_website    => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
        });

        $t->put_ok(
            "/api/politician/$politician_id",
            form => {
                picframe_url  => 'https://foobar.com.br',
                picframe_text => 'foobar'
            }
        )
    };

    subtest 'Chatbot | Get politician data' => sub {
        $t->get_ok(
            '/api/chatbot/politician',
            form => {
                security_token => $security_token,
                fb_page_id     => 'FOO',
                platform       => 'fb'
            }
        )
        ->status_is(200)
        ->json_is('/user_id',                                  $politician_id,                                                         'user_id')
        ->json_is('/name',                                     "Lucas Ansei",                                                          'name')
        ->json_is('/address_state',                            26,                                                                     'address_state')
        ->json_is('/address_city',                             9508,                                                                   'address_city')
        ->json_is('/gender',                                   $gender,                                                                'gender')
        ->json_is('/contact/twitter',                          '@foobar',                                                              'twitter')
        ->json_is('/contact/email',                            $email,                                                                 'email')
        ->json_is('/contact/url',                              "https://www.google.com",                                               'url')
        ->json_is('/picframe_url',                             'https://foobar.com.br',                                                'picframe_url' )
        ->json_is('/picframe_text',                            'foobar',                                                               'picframe_text' )
        ->json_is('/share/url',                                'https://foobar.com.br',                                                'share url' )
        ->json_is('/share/text',                               'foobar',                                                               'share text' )
        ->json_is('/votolegal_integration/votolegal_username', 'fake_username',                                                        'voto legal username')
        ->json_is('/votolegal_integration/votolegal_url',      'https://dev.votolegal.com.br/em/fake_username?ref=mandatoaberto#doar', 'voto legal url')
        ->json_is('/greeting', 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.', 'greeting content');

        # Testing twitter
        db_transaction{
            $politician->update(
                {
                    twitter_id           => 'foobar',
                    twitter_oauth_token  => 'bar',
                    twitter_token_secret => 'baz'
                }
            );

            $t->get_ok(
                '/api/chatbot/politician',
                form => {
                    platform       => 'twitter',
                    twitter_id     => 'foobar',
                    security_token => $security_token
                }
            )
            ->status_is(200)
            ->json_is('/twitter_oauth_token',  'bar', 'twitter_oauth_token')
            ->json_is('/twitter_token_secret', 'baz', 'twitter_token_secret');
        };
    };

    subtest 'Chatbot | Get politician data --invalid' => sub {

        # Invalid platform
        $t->get_ok(
            '/api/chatbot/politician',
            form => {
                security_token => $security_token,
                fb_page_id     => 'FOO',
                platform       => 'FOO'
            }
        )
        ->status_is(400);

        # Non existent twitter_id
        $t->get_ok(
            '/api/chatbot/politician',
            form => {
                platform       => 'twitter',
                twitter_id     => 'foobar',
                security_token => $security_token
            }
        )
        ->status_is(400);
    };
};

done_testing();