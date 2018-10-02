package MandatoAberto::Controller::Admin::Politician::Approve;
use Mojo::Base 'MandatoAberto::Controller';

sub post {
    my $c = shift;

    use DDP; p $c->is_user_authenticated;
    # TODO assert role.
    my $admin_id = $c->current_user->id;

    my $politician_id = $c->req->params->{politician_id};
    die \['politician_id', 'missing'] unless $politician_id;

    my $politician = $c->stash->{collection}->find($politician_id);
    die \['politician_id', 'could not find politician with that id'] unless $politician;

    die \['approved', 'missing'] unless exists $c->req->params->{approved};
    my $approved = $c->req->params->{approved};

    my $current_approved_status = $politician->user->approved;
    die \["approved", "politician current alredy is: $current_approved_status"] if $current_approved_status == $approved;

    if ( $approved ) {
        $politician->user->approve($admin_id);
    } else {
        $politician->user->disapprove($admin_id);
    }

    return $c->status_ok(
        $c,
        entity => {
            id => $politician->id,
        }
    );
}

1;
