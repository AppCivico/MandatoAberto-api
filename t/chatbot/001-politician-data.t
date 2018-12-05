use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $party    = fake_int(1, 35)->();
    my $office   = fake_int(1, 8)->();
    my $gender   = fake_pick(qw/F M/)->();
    my $email    = fake_email()->();
    my $password = 'foobar';

    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician(
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
    my $politician_id = stash "politician.id";
    my $politician    = $schema->resultset("Politician")->find($politician_id);

    api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

    &setup_votolegal_integration_success;
    rest_post "/api/politician/$politician_id/votolegal-integration",
        name                => "Creating Voto Legal integration",
        automatic_load_item => 0,
        [ votolegal_email  => 'foobar@email.com' ]
    ;

    $schema->resultset("PoliticianContact")->create({
        organization_chatbot_id => $organization_chatbot_id,
        twitter                 => '@foobar',
        url                     => "https://www.google.com",
        email                   => $email
    });

    $schema->resultset("PoliticianGreeting")->create({
        organization_chatbot_id => $organization_chatbot_id,
        on_facebook             => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
        on_website              => 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.'
    });

    rest_put "/api/politician/$politician_id",
        name => "Adding picframe URL",
        [
            picframe_url  => 'https://foobar.com.br',
            picframe_text => 'foobar'
        ]
    ;

    rest_get "/api/chatbot/politician",
        name  => "get politician data",
        list  => 1,
        stash => "get_politician_data",
        [
            fb_page_id     => "fake_page_id",
            security_token => $security_token
        ]
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        is ($res->{user_id},                                     $politician_id,                                                         'user_id');
        is ($res->{name},                                        "Lucas Ansei",                                                          'name');
        is ($res->{address_state},                               26 ,                                                                    'address_state');
        is ($res->{address_city},                                9508 ,                                                                  'address_city');
        is ($res->{gender},                                      $gender ,                                                               'gender');
        is ($res->{contact}->{twitter},                          '@foobar',                                                              'twitter');
        is ($res->{contact}->{email},                            $email,                                                                 'email');
        is ($res->{contact}->{url},                              "https://www.google.com",                                               'url');
        is ($res->{picframe_url},                                'https://foobar.com.br',                                                'picframe_url' );
        is ($res->{picframe_text},                               'foobar',                                                               'picframe_text' );
        is ($res->{share}->{url},                                'https://foobar.com.br',                                                'share url' );
        is ($res->{share}->{text},                               'foobar',                                                               'share text' );
        is ($res->{votolegal_integration}->{votolegal_username}, 'fake_username',                                                        'voto legal username');
        is ($res->{votolegal_integration}->{votolegal_url},      'https://dev.votolegal.com.br/em/fake_username?ref=mandatoaberto#doar', 'voto legal url');
        is ($res->{greeting}, 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.', 'greeting content');
    };

    rest_get "/api/chatbot/politician",
        name    => "get politician data with invalid platform",
        is_fail => 1,
        code    => 400,
        [
            platform       => 'FOO',
            security_token => $security_token
        ]
    ;

    rest_get '/api/chatbot/politician',
        name    => 'get politician data with non existent twitter_id',
        is_fail => 1,
        code    => 400,
        [
            platform       => 'twitter',
            twitter_id     => 'foobar',
            security_token => $security_token
        ]
    ;

    $politician->update(
        {
            twitter_id           => 'foobar',
            twitter_oauth_token  => 'bar',
            twitter_token_secret => 'baz'
        }
    );

    rest_get '/api/chatbot/politician',
        name  => 'get politician data with non existent twitter_id',
        list  => 1,
        stash => 'politician_data_twitter',
        [
            platform       => 'twitter',
            twitter_id     => 'foobar',
            security_token => $security_token
        ]
    ;

    stash_test "politician_data_twitter" => sub {
        my $res = shift;

        is ($res->{twitter_oauth_token},  'bar', 'twitter_oauth_token');
        is ($res->{twitter_token_secret}, 'baz', 'twitter_token_secret');
    };
};

done_testing();