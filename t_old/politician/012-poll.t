use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $politician    = create_politician( fb_page_id => 'foobar' );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    api_auth_as user_id => $politician_id;
    activate_chatbot($politician_id);

    $politician->user->update( { approved => 1 } );

    create_recipient( politician_id => $politician_id );

    $politician->user->organization_chatbot->poll_self_propagation_config->update( { active => 1 } );

    # Mantendo o jeito antigo de cadastrar enquetes
    # até a mudança ser feita no front-end
    rest_post "/api/register/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p1",
        [
            name                       => 'foobar',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;
    my $first_poll_id = stash "p1.id";

    rest_post "/api/politician/$politician_id/poll",
        name                => "Sucessful poll creation",
        automatic_load_item => 0,
        stash               => "p2",
        [
            name                       => 'bazbar',
            status_id                  => 1,
            'questions[0]'             => 'Você está bem?',
            'questions[0][options][0]' => 'Sim',
            'questions[0][options][1]' => 'Não',
            'questions[1]'             => 'foobar?',
            'questions[1][options][0]' => 'foo',
            'questions[1][options][1]' => 'bar',
            'questions[1][options][2]' => 'não',
        ]
    ;
    my $second_poll_id = stash "p2.id";

    rest_get "/api/politician/$politician_id/poll",
        name  => "list polls and respective questions",
        list  => 1,
        stash => "get_polls"
    ;

    stash_test "get_polls" => sub {
        my $res = shift;

        my $first_poll  = $res->{polls}->[0];
        my $second_poll = $res->{polls}->[1];

        is ($first_poll->{name},       'foobar', 'first poll name');
        is ($second_poll->{name},      'bazbar', 'second poll name');
    };
};

done_testing();
