package MandatoAberto::Controller::API::Politician::Greeting;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    result  => "DB::PoliticianGreeting",
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

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $politician_greeting_id ) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $politician_greeting_id } );

    my $politician_greeting = $c->stash->{collection}->find($politician_greeting_id);
    $c->detach("/error_404") unless ref $politician_greeting;

    $c->stash->{politician_greeting} = $politician_greeting;

    $c->stash->{is_me} = int( $c->user->id == $politician_greeting->politician_id );
    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ( $self, $c ) = @_;

    my $politician_greeting = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{ $c->req->params }, politician_id => $c->user->id,
          }

    );

    # $c->slack_notify("O usuário '${\($user->user->name)}' se cadastrou na plataforma como doador.") unless is_test();

    return $self->status_created(
        $c,
        location =>
          $c->uri_for( $self->action_for('result'), [ $c->stash->{politician}->user_id, $politician_greeting->id ] ),
        entity => {
            id            => $politician_greeting->id,
            politician_id => $politician_greeting->politician_id,
            text          => $politician_greeting->text
        },
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

=encoding utf8

=head1 AUTHOR

  Jordan Eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
