package MandatoAberto::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

MandatoAberto::Controller::Root - Root Controller for MandatoAberto

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;

    return $c->detach("/error_404");
}

sub error_404 : Private {
    my ($self, $c) = @_;

    return $self->status_not_found($c, message => "Endpoint not found.");
}

sub error_403 : Private {
    my ($self, $c) = @_;

    return $self->status_forbidden($c, message => "Endpoint forbidden.");
}

=head1 AUTHOR

lucas-eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
