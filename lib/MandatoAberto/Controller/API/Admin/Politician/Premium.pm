package MandatoAberto::Controller::API::Admin::Politician::Premium;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/admin/politician/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('premium') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \['politician_id', 'missing'] unless $politician_id;

    my $politician = $c->stash->{collection}->find($politician_id);
    die \['politician_id', 'could not find politician with that id'] unless $politician;

    die \['premium', 'missing'] unless exists $c->req->params->{premium};
    my $premium = $c->req->params->{premium};

    my $current_premium_status = $politician->premium;
    die \[
        "premium",
        "politician current premium status alredy is: $current_premium_status"
    ] if $current_premium_status == $premium;

    if ( $premium ) {
        $politician->activate_premium;
    } else {
        $politician->deactivate_premium;
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