package MandatoAberto::Controller::API::Politician::Dashboard;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dashboard') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $citizen_count = $c->model("DB::Citizen")->search( { politician_id => $politician_id } )->count;

    return $self->status_ok(
        $c,
        entity => {
            citizens => $citizen_count
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;