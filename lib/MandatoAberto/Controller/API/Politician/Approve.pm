package MandatoAberto::Controller::API::Politician::Approve;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/admin/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('approve') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $approved = $c->req->params->{approved};
    die \["approved", 'missing'] unless defined $approved;

    my $politician_user = $c->stash->{politician}->user;

    $politician_user->update(
        {
            approved    => $approved,
            approved_at => \'NOW()'
        }
    );

    $politician_user->send_email_approved();

    return $self->status_ok(
        $c,
        entity => {
            id => $politician_user->id
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;