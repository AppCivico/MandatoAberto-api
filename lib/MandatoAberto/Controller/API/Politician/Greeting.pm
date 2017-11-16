package MandatoAberto::Controller::API::Politician::Greeting;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    result  => "DB::Politician::Greeting",
    no_user => 1,
);

=head1 NAME

MandatoAberto::Controller::Greeting - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('greeting') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

   #  $c->slack_notify("O usuário '${\($user->user->name)}' se cadastrou na plataforma como doador.") unless is_test();

    return $self->status_created(
        $c,
        location => $c->uri_for( $c->controller("DB::Politician::Greeting")->action_for('result'), [ $user->id ] ),
        entity => { user_id => $user->id },
    );
}

=encoding utf8
=head1 AUTHOR

  Jordan Eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
