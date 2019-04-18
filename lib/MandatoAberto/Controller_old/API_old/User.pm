package MandatoAberto::Controller::API::User;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::User');
}

sub base : Chained('root') : PathPart('user') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $user_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $user_id } );

    my $user = $c->stash->{collection}->find($user_id);
    $c->detach("/error_404") unless ref $user;

    $c->stash->{is_me} = int($c->user->id == $user->id);
    $c->stash->{user}  = $user;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => $c->stash->{user}->build_result_get
    );
}

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;

