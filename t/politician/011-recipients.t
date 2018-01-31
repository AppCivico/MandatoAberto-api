use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model('DB');

db_transaction {
    create_politician;
    my $politician_id = stash 'politician.id';

    my @recipient_ids = ();
    subtest 'mocking recipients' => sub {

        # Criando três recipients.
        for (my $i = 0; $i <= 3; $i++) {
            create_recipient(politician_id => $politician_id);

            my $recipient_id = stash 'recipient.id';
            push @recipient_ids, $recipient_id;
        }
    };

    api_auth_as user_id => $politician_id;

    subtest 'list recipients' => sub {

        rest_get "/api/politician/$politician_id/recipients",
            name  => 'list recipients',
            stash => 'recipients',
        ;

        stash_test 'recipients' => sub {
            my $res = shift;

            is( ref($res->{recipients}), 'ARRAY', 'recipients=arrayref' );
            is( scalar(@{ $res->{recipients} }), '4', 'count=4' );

            is_deeply(
                [ sort keys %{ $res->{recipients}->[0] } ],
                [ sort qw/ id name cellphone email origin_dialog created_at gender / ],
            );
        };
    };

    subtest 'get recipient' => sub {

        # Adicionando um grupo.
        rest_post "/api/politician/$politician_id/group",
            name    => 'add group',
            stash   => 'Fake Group',
            headers => [ 'Content-Type' => 'application/json' ],
            data    => encode_json({
                name     => fake_name->(),
                filter   => {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'QUESTION_IS_NOT_ANSWERED',
                            data => { field => '32' },
                        },
                    ],
                },
            }),
        ;

        my $group_id = stash 'group.id';
        my $recipient_id = stash 'recipient.id';

        ok( my $recipient = $schema->resultset('Recipient')->find($recipient_id), 'get recipient' );
        ok( $recipient->add_to_group($group_id), 'add recipient to group' );

        p $recipient->discard_changes;

        rest_get "/api/politician/$politician_id/recipients/$recipient_id",
            name  => 'get recipient',
            stash => 'get_recipient',
        ;

        stash_test 'get_recipient' => sub {
            my $res = shift;

            p $res;
        };
    };
};

done_testing();

