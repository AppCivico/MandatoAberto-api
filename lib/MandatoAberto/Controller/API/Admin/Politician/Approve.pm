package MandatoAberto::Controller::API::Admin::Politician::Approve;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/admin/politician/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('approve') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \['politician_id', 'missing'] unless $politician_id;

    my $politician = $c->stash->{collection}->find($politician_id);
    die \['politician_id', 'could not find politician with that id'] unless $politician;

    die \['approved', 'missing'] unless exists $c->req->params->{approved};
    my $approved = $c->req->params->{approved};

    my $current_approved_status = $politician->user->approved;
    die \["approved", "politician current alredy is: $current_approved_status"] if $current_approved_status == $approved;

    if ( $approved ) {
        $politician->user->approve;
    } else {
        $politician->user->disapprove;
    }

    return $self->status_ok(
        $c,
        entity => {
            id => $politician->id,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;