package MandatoAberto::Controller::API::User;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::User",

    # AutoResultPUT.
    object_key     => "user",
    result_put_for => "update",
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('user') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ($self, $c, $id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $id } );

    my $user = $c->stash->{collection}->find($id);
    $c->detach("/error_404") unless ref $user;

    $c->stash->{is_me} = int($c->user->id == $user->id);

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $c->stash->{user}->$_ } qw/email/ )
        }
    );
}

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;