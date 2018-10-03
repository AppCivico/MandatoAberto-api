use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test;

my $t = test_instance;
my $schema = $t->app->schema;

db_transaction {
    my $politician = create_politician;
    my $politician_id = $politician->{id};

    subtest 'Politician | contact' => sub {

        api_auth_as user_id => 1;
        $t->post_ok("/api/politician/$politician_id/contact")
        ->status_is(403);

        # Facebook must be an URI
        api_auth_as user_id => $politician_id;
        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                facebook => 'Foobar',
            }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                email => 'Foobar',
            }
        )
        ->status_is(400);

        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => { url => 'foobar' },
        )
        ->status_is(400);

        my $twitter  = '@lucas_ansei';
        my $facebook = 'https://facebook.com/lucasansei';

        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                twitter  => '@lucas_ansei',
                facebook => 'https://facebook.com/lucasansei',
                email    => 'foobar@email.com',
                url      => 'https://www.google.com'
            }
        )
        ->status_is(200);

        my $contact = $t->tx->res->json;

        $t->get_ok("/api/politician/$politician_id/contact")
        ->json_is('/politician_contact/id',        $contact->{id}, 'id')
        ->json_is('/politician_contact/facebook',  'https://facebook.com/lucasansei', 'facebook')
        ->json_is('/politician_contact/twitter',   '@lucas_ansei', 'twitter')
        ->json_is('/politician_contact/email',     'foobar@email.com', 'email')
        ->json_is('/politician_contact/url',       'https://www.google.com', 'url')
        ->json_is('/politician_contact/cellphone', undef, 'cellphone');

        # Update politician contact.
        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => {
                twitter  => '@foobar',
                facebook => 'https://facebook.com/aaaa',
                email    => 'foobar@aaaaa.com',
            }
        )
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/contact")
        ->json_is('/politician_contact/id',        $contact->{id}, 'id')
        ->json_is('/politician_contact/facebook',  'https://facebook.com/aaaa', 'facebook')
        ->json_is('/politician_contact/twitter',   '@foobar', 'twitter')
        ->json_is('/politician_contact/email',     'foobar@aaaaa.com', 'email')
        ->json_is('/politician_contact/cellphone', undef, 'cellphone');

        # Remove contacts.
        $t->post_ok("/api/politician/$politician_id/contact")
        ->status_is(200);

        $t->get_ok("/api/politician/$politician_id/contact")
        ->json_is('/politician_contact/id',        $contact->{id}, 'id')
        ->json_is('/politician_contact/facebook',  undef, 'facebook')
        ->json_is('/politician_contact/twitter',   undef, 'twitter')
        ->json_is('/politician_contact/email',     undef, 'email')
        ->json_is('/politician_contact/cellphone', undef, 'cellphone')
        ->json_is('/politician_contact/instagram', undef, 'instagram');

        # Add instagram.
        $t->post_ok(
            "/api/politician/$politician_id/contact",
            form => { instagram => 'https://www.instagram.com/lucasansei/' }
        );

        $t->get_ok("/api/politician/$politician_id/contact")
        ->json_is('/politician_contact/id',        $contact->{id}, 'id')
        ->json_is('/politician_contact/facebook',  undef, 'facebook')
        ->json_is('/politician_contact/twitter',   undef, 'twitter')
        ->json_is('/politician_contact/email',     undef, 'email')
        ->json_is('/politician_contact/cellphone', undef, 'cellphone')
        ->json_is('/politician_contact/instagram', 'https://www.instagram.com/lucasansei/', 'instagram');
    };
};

done_testing();
