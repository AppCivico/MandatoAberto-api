package MandatoAberto::Controller::Admin::Politician::Approve;
use Mojo::Base 'MandatoAberto::Controller';

sub post {
    my $c = shift;

    # TODO assert role.
    my $admin_id = $c->current_user->id;

    $c->validate_request_params(
        politician_id => {
            type     => 'Int',
            required => 1,
        },
        approved => {
            type     => 'Bool',
            required => 1,
        },
    );

    my $politician_id = $c->req->param('politician_id');
    my $approved = $c->req->param('approved');

    my $politician = $c->schema->resultset('Politician')->find($politician_id);

    my $current_approved_status = $politician->user->get_column('approved');
    die \["approved", "politician current alredy is: $current_approved_status"] if $current_approved_status == $approved;

    if ($approved) {
        $politician->user->approve($admin_id);
    } else {
        $politician->user->disapprove($admin_id);
    }

    return $c->render(
        json   => { id => $politician->id },
        status => 200,
    );
}

1;
