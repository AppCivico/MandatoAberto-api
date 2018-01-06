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

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ( $self, $c ) = @_;

    my $politician_greeting = $c->stash->{collection}->execute(
        $c,
        for  => 'create',
        with => {
            %{ $c->req->params },
            politician_id => $c->user->id,
          }

    );

    return $self->status_ok(
        $c,
        entity => {
            id => $politician_greeting->id
        },
    );
}

sub list_GET {
    my ( $self, $c ) = @_;

    my $politician_id = $c->user->id;

    my $selected_greeting = $c->stash->{collection}->search( { politician_id => $politician_id } )->next;

    return $self->status_ok(
        $c,
        entity => {
            greetings => {
                selected => $selected_greeting->greeting_id,
                list => [
                    map {

                        my $g = $_;

                        my $greeting_id = $g->get_column('id');
                        +{
                            id       => $greeting_id,
                            content  => $g->get_column('content'),
                        }

                    } $c->model("DB::Greeting")->search(
                        undef,
                        { prefetch => 'politicians_greeting' }
                    )->all()
                ]
            }
        }
    );
}

=cut

=encoding utf8

=head1 AUTHOR

  Jordan Eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
