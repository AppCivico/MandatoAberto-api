package MandatoAberto::Controller::API::Login::Confirm;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/login/base') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::UserConfirmation');
}

sub base : Chained('root') : PathPart('confirm') : CaptureArgs(0) { }

sub confirm : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub confirm_POST {
    my ($self, $c) = @_;

    $c->stash->{collection}->execute(
        $c,
        for  => "confirm",
        with => $c->req->params,
    );

    return $self->status_ok($c, entity => { message => "ok" });
}

=encoding utf8

=head1 AUTHOR

Junior Moraes,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
