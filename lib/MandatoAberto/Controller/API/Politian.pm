package MandatoAberto::Controller::API::Politian;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politian",

    # AutoResultPUT.
    object_key     => "politian",
    result_put_for => "update",
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politian') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $user_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { user_id => $user_id } );

    my $user = $c->stash->{collection}->find($user_id);
    $c->detach("/error_404") unless ref $user;

    $c->stash->{is_me}    = int($c->user->id == $user->id);
    $c->stash->{politian} = $user;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    #TODO retornar nome do partido e cargo (party_id e office_id)
    return $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $c->stash->{politian}->$_ } qw/
                name address_city address_state approved
                party_id office_id fb_page_id fb_app_id
                fb_app_secret fb_page_acess_token/ ),

            ( map { $_ => $c->stash->{politian}->user->$_ } qw/id email created_at/ ),

        }
    );
}

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;