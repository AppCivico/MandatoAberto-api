use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $chatbot_security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    create_politician();
    my $politician_id = stash "politician.id";

    api_auth_as "user_id" => $politician_id;
	activate_chatbot($politician_id);

    setup_votolegal_integration_success();

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name                => "Creating Voto Legal integration",
        automatic_load_item => 0,
        [ votolegal_email  => 'foobar@email.com' ]
    ;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Integration with logged_in_greeting greater than 80 chars",
        is_fail => 1,
        code    => 400,
        [
            votolegal_email => 'foobar@email.com',
            greeting        => 'This is just a large phrase repeated over and over. This is just a large phrase repeated over and over.'
        ]
    ;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Integration without votolegal_email",
        is_fail => 1,
        code    => 400,
    ;

    setup_votolegal_integration_fail();

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Integration with non-existent votolegal_email",
        is_fail => 1,
        code    => 400,
        [ votolegal_email => 'thisisonlyatestemail@email.com' ]
    ;

    rest_get "/api/chatbot/politician",
        name  => 'get politician data',
        list  => 1,
        stash => 'get_politician_data',
        [
            security_token => $chatbot_security_token,
            fb_page_id     => 'fake_page_id'
        ]
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        my $votolegal_integration = $res->{votolegal_integration};

        is ( $votolegal_integration->{votolegal_username}, 'fake_username', 'voto legal username' );
        ok ( defined( $votolegal_integration->{votolegal_url} ) , 'voto legal url' );
    };

    db_transaction {
        setup_votolegal_integration_success_with_custom_url();
        rest_post "/api/politician/$politician_id/votolegal-integration",
          name                => "Creating Voto Legal integration",
          automatic_load_item => 0,
          [ votolegal_email  => 'foobar@email.com' ];

        rest_reload_list 'get_politician_data';
        stash_test "get_politician_data.list" => sub {
            my $res = shift;

            my $votolegal_integration = $res->{votolegal_integration};

            is( $votolegal_integration->{votolegal_username}, 'fake_username', 'voto legal username' );
            ok( defined( $votolegal_integration->{votolegal_url} ), 'voto legal url' );
            is( $votolegal_integration->{votolegal_url}, 'https://www.foobar.com.br?ref=mandatoaberto#doar', 'custom_url' );
        };
    };

    create_politician();
    my $second_politician_id = stash "politician.id";

    api_auth_as user_id => $second_politician_id;

    rest_post "/api/politician/$politician_id/votolegal-integration",
        name    => "Can't create voto legal integration for other user",
        is_fail => 1,
        code    => 403,
        [ votolegal_email  => 'foobar@email.com' ]
    ;

    rest_get "/api/chatbot/politician",
        name => 'get politician chatbot data',
        list => 1,
        stash => 'get_politician_chatbot_data',
        [
            security_token => $chatbot_security_token,
            fb_page_id     => 'fake_page_id'
        ]
    ;

    stash_test "get_politician_chatbot_data" => sub {
        my $res = shift;

        ok ( defined( $res->{votolegal_integration} ),            'votolegal_integration object is defined' );
        is ( $res->{votolegal_integration}->{votolegal_url},      'https://dev.votolegal.com.br/em/fake_username?ref=mandatoaberto#doar', 'votolegal url' );
        is ( $res->{votolegal_integration}->{votolegal_username}, 'fake_username',                                                        'votolegal username' );
    };

    api_auth_as user_id => $politician_id;

    rest_get "/api/politician/$politician_id",
        name => 'get politician data',
        list => 1,
        stash => 'get_politician_data',
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        ok ( defined( $res->{votolegal_integration} ),            'votolegal_integration object is defined' );
        is ( $res->{votolegal_integration}->{votolegal_email},      'foobar@email.com', 'votolegal email' );
        is ( $res->{votolegal_integration}->{greeting}, undef,     'votolegal greeting' );
    };

    # Deactivating integration
    rest_post "/api/politician/$politician_id/votolegal-integration",
        name                => "Creating Voto Legal integration",
        automatic_load_item => 0,
        [
            votolegal_email  => 'foobar@email.com',
            active           => 0
        ]
    ;

    rest_reload_list 'get_politician_data';
    stash_test "get_politician_data.list" => sub {
        my $res = shift;

        is( $res->{votolegal_integration}, undef, 'votolegal integration does not exists' );
    };

};

done_testing();