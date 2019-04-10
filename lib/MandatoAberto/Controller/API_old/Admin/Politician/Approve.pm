package MandatoAberto::Controller::API::Admin::Politician::Approve;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/admin/politician/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('approve') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::User');

    my $admin_id = $c->user->id;

    my $user_id = $c->req->params->{politician_id};
    die \['politician_id', 'missing'] unless $user_id;

    my $user = $c->stash->{collection}->find($user_id);
    die \['politician_id', 'could not find politician with that id'] unless $user;

    die \['approved', 'missing'] unless exists $c->req->params->{approved};
    my $approved = $c->req->params->{approved};

    my $current_approved_status = $user->approved;
    die \["approved", "politician current alredy is: $current_approved_status"] if $current_approved_status == $approved;

    if ( $approved ) {
        $user->approve($admin_id);
    } else {

        $user->disapprove($admin_id);
    }

    return $self->status_ok(
        $c,
        entity => {
            id => $user->id,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;