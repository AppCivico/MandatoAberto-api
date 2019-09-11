package MandatoAberto::Controller::API::Politician::Users;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('users') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->user->organization->users;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            users => [
                map {
                    my $u = $_->user;

                    +{
                        id => $u->id,
                        name => $u->name
                    }
                } $c->stash->{collection}->all
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;