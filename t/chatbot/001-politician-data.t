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

    $schema->resultset("PoliticianContact")->create({
        politician_id => $politician_id,
        twitter       => '@foobar',
        url           => "https://www.google.com",
        email         => $email
    });

    $schema->resultset("PoliticianGreeting")->create({
        politician_id => $politician_id,
        greeting_id   => 1
    });

    rest_get "/api/chatbot/politician",
        name  => "get politician data",
        list  => 1,
        stash => "get_politician_data",
        [
            fb_page_id     => "FOO",
            security_token => $security_token
        ]
    ;

    stash_test "get_politician_data" => sub {
        my $res = shift;

        is ($res->{user_id}, $politician_id, 'user_id');
        is ($res->{name}, "Lucas Ansei", 'name');
        is ($res->{address_state}, 26 , 'address_state');
        is ($res->{address_city}, 9508 , 'address_city');
        is ($res->{gender}, $gender , 'gender');
        is ($res->{contact}->{twitter}, '@foobar', 'twitter');
        is ($res->{contact}->{email}, $email, 'email');
        is ($res->{contact}->{url}, "https://www.google.com", 'url');
        is ($res->{greeting}, 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil a melhor e precisamos de sua ajuda.', 'greeting content');
    };
};

done_testing();