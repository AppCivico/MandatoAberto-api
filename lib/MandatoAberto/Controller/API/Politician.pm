package MandatoAberto::Controller::API::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Politician",

    # AutoResultPUT.
    object_key     => "politician",
    result_put_for => "update",
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $user_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { user_id => $user_id } );

    my $user = $c->stash->{collection}->find($user_id);
    $c->detach("/error_404") unless ref $user;

    $c->stash->{is_me}    = int($c->user->id == $user->id);
    $c->stash->{politician} = $user;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $c->stash->{politician}->$_ } qw/
                name address_city address_state
                fb_page_id fb_app_id fb_app_secret
                fb_page_acess_token gender/ ),

            ( party => { map { $_ => $c->stash->{politician}->party->$_ } qw/acronym name id/ } ),

            ( office => { map { $_ => $c->stash->{politician}->office->$_ } qw/id name/ } ),

            (
                contact => {
                    map {
                        my $c = $_;

                        id        => $c->get_column('id'),
                        twitter   => $c->get_column('twitter'),
                        facebook  => $c->get_column('facebook'),
                        email     => $c->get_column('email'),
                        cellphone => $c->get_column('cellphone'),
                    } $c->model("DB::PoliticianContact")->search( { politician_id => $c->user->id } )
                }
            ),

            (
                greeting => {
                    map {
                        my $g = $_;

                        id   => $g->get_column('id'),
                        text => $g->get_column('text')
                    } $c->model("DB::PoliticianGreeting")->search( { politician_id => $c->user->id } )
                }
            ),

            ( map { $_ => $c->stash->{politician}->user->$_ } qw/id email approved created_at/ ),

        }
    );
}

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;