use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $issue_rs      = $schema->resultset('Issue');
    my $recipient_rs  = $schema->resultset('Recipient');
    my $politician_rs = $schema->resultset('Politician');

    my $politician    = create_politician();
    my $politician_id = $politician->{id};
    $politician       = $politician_rs->find($politician_id);

	api_auth_as user_id => $politician_id;
	activate_chatbot($politician_id);

    my $recipient_id = create_recipient( politician_id => $politician_id );
    my $recipient    = $recipient_rs->find($recipient_id);

    my $issue = create_issue(
        fb_id         => $recipient->fb_id,
        politician_id => $politician_id
    );
    my $issue_id = $issue->{id};
    $issue       = $issue_rs->find($issue_id);

    rest_get "/api/politician/$politician_id/issue",
        name  => 'get open issues',
        stash => 'get_open_issues',
        list  => 1,
        [ filter => 'open' ]
    ;

    stash_test 'get_open_issues' => sub {
        my $res = shift;

        is( scalar @{ $res->{issues} }, 1, '1 issue on list' );
    };

    # Testando com issue ignorada
    db_transaction{
        ok( $issue = $issue->update( { open => 0 } ), 'ignoring issue' );

        rest_get "/api/politician/$politician_id/issue",
            name  => 'get ignored issues',
            stash => 'get_ignored_issues',
            list  => 1,
            [ filter => 'ignored' ]
        ;

        stash_test 'get_ignored_issues' => sub {
            my $res = shift;

            is( scalar @{ $res->{issues} }, 1, '1 ignored issue' );
        };

        rest_put "/api/politician/$politician_id/issue/$issue_id",
            name => 'deleting issue',
            [ deleted => 1 ]
        ;

        rest_reload_list 'get_ignored_issues';
        stash_test 'get_ignored_issues.list' => sub {
            my $res = shift;

            is( scalar @{ $res->{issues} }, 0, 'issue has been deleted' );
        };
    };

    # Testando batch delete
    db_transaction{
        my $second_issue = create_issue(
            fb_id         => $recipient->fb_id,
            politician_id => $politician_id
        );
        my $second_issue_id = $second_issue->{id};
        $second_issue       = $issue_rs->find($second_issue_id);

        rest_put "/api/politician/$politician_id/issue/batch-delete",
            name => 'batch delete',
            code => 200,
            [ ids => "$issue_id, $second_issue_id" ]
        ;

        is( $issue_rs->search( { deleted => 1 } )->count, 2, '2 issues deleted' );
    };
};

done_testing();