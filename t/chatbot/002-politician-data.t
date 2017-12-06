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
    my $password = "foobar";

    create_politician(
        email                => $email,
        password             => $password,
        name                 => "Lucas Ansei",
        address_state        => 'SP',
        address_city         => 'São Paulo',
        party_id             => $party,
        office_id            => $office,
        fb_page_id           => "FOO",
        fb_app_id            => "BAR",
        fb_app_secret        => "foobar",
        fb_page_access_token => "FOOBAR",
        gender               => $gender,
    );
    my $politician_id = stash "politician.id";

    $schema->resultset("PoliticianContact")->create({
        politician_id => $politician_id,
        twitter       => '@foobar',
        email         => $email
    });

    $schema->resultset("PoliticianGreeting")->create({
        politician_id => $politician_id,
        text          => "Foobar"
    });

    my $politician_chatbot = $schema->resultset("PoliticianChatbot")->search( { politician_id => $politician_id } )->next;

    api_auth_as user_id => $politician_chatbot->id;

    rest_get "/api/chatbot/politician",
        name  => "get politician data",
        list  => 1,
        stash => "get_politician_data"
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        is ($res->{user_id}, $politician_id, 'user_id');
        is ($res->{name}, "Lucas Ansei", 'name');
        is ($res->{address_state}, "SP" , 'address_state');
        is ($res->{address_city}, "São Paulo" , 'address_city');
        is ($res->{gender}, $gender , 'gender');
        is ($res->{contact}->{twitter}, '@foobar', 'twitter');
        is ($res->{contact}->{email}, $email, 'email');
        is ($res->{greeting}, 'Foobar', 'greeting content');
    };
};

done_testing();