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
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        my $share_url  = $c->req->params->{picframe_url}  || $c->req->params->{share_url};
        my $share_text = $c->req->params->{picframe_text} || $c->req->params->{share_text};

        $params->{share_url}  = $share_url;
        $params->{share_text} = $share_text;

        if ( (defined $c->req->params->{picframe_url} && $c->req->params->{picframe_url} eq '') || (defined $c->req->params->{share_url} && $c->req->params->{share_url} eq '') ) {
            $params->{share_url} = 'SET_NULL';
        }
		if ( (defined $c->req->params->{picframe_text} && $c->req->params->{picframe_text} eq '') || (defined $c->req->params->{share_text} && $c->req->params->{share_text} eq '') ) {
            $params->{share_text} = 'SET_NULL';
		}

        return $params;
    },
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_any_user_role(qw/ politician admin /) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('politician') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $user_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { user_id => $user_id } );

    my $user = $c->stash->{collection}->find($user_id);
    $c->detach("/error_404") unless ref $user;

    $c->stash->{is_me}    = int($c->user->id == $user->id);
    $c->stash->{politician} = $user;

}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result_GET {
    my ($self, $c) = @_;

    my $facebook_active_page = {};
    if ($c->stash->{politician}->fb_page_id) {
        $facebook_active_page = $c->stash->{politician}->get_current_facebook_page();
    }

    my $votolegal_integration = $c->stash->{politician}->get_votolegal_integration if $c->stash->{politician}->has_votolegal_integration;

    my $has_movement = $c->stash->{politician}->movement ? 1 : 0;

    return $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $c->stash->{politician}->$_ } qw/
                name gender premium twitter_id/ ),

            picframe_url  => $c->stash->{politician}->share_url,
            picframe_text => $c->stash->{politician}->share_text,
            share_url     => $c->stash->{politician}->share_url,
            share_text    => $c->stash->{politician}->share_text,

            fb_page_id => $facebook_active_page ? $c->stash->{politician}->fb_page_id : undef,

            ( $has_movement ? ( movement => { map { $_ => $c->stash->{politician}->movement->$_ } qw/name id/  } ) : () ),

            ( state => { map { $_ => $c->stash->{politician}->address_state->$_ } qw/name code/  } ),

            ( city => {map { $_ => $c->stash->{politician}->address_city->$_ } qw/name id/}  ),

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
                        url       => $c->get_column('url'),
                    } $c->model("DB::PoliticianContact")->search( { politician_id => $c->user->id } )
                }
            ),

            (
                greeting => {
                    map {
                        my $g = $_;

                        id          => $g->get_column('id'),
                        on_facebook => $g->get_column('on_facebook'),
                        on_website  => $g->get_column('on_website')
                    } $c->model("DB::PoliticianGreeting")->search(
                        { politician_id => $c->user->id },
                        { prefetch => 'greeting' }
                    )
                }
            ),

            ( map { $_ => $c->stash->{politician}->user->$_ } qw/id email approved created_at/ ),

            facebook_active_page => $facebook_active_page,

            ( $votolegal_integration ?
                (
                    votolegal_integration => {
                        votolegal_email => $votolegal_integration->votolegal_email,
                        greeting        => $votolegal_integration->greeting
                    }
                ) : ()
            )
        }
    );
}

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;
