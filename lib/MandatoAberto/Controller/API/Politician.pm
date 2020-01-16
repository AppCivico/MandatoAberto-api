package MandatoAberto::Controller::API::Politician;
use common::sense;
use Moose;
use namespace::autoclean;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

use WebService::GoogleDrive;

has _drive => (
    is         => "ro",
    isa        => "WebService::GoogleDrive",
    lazy_build => 1,
);

sub _build__drive { WebService::GoogleDrive->instance }

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

        if ( my $upload = $c->req->upload("picture") ) {
            my $picture_url = $self->_upload_picture($upload);

            $params->{picture} = $picture_url;
        }

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

    $c->stash->{is_me}      = int($c->user->id == $user->id);
    $c->stash->{politician} = $user;
    $c->stash->{chatbot}    = $c->stash->{politician}->user->organization->chatbot;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    # Asserting user role for module
    eval { $c->assert_user_roles(qw/general_profile_read general_profile_update/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub result_GET {
    my ($self, $c) = @_;

    my $facebook_active_page;
    if ($c->stash->{politician}->user->organization_chatbot->fb_config) {
        $facebook_active_page = $c->stash->{politician}->get_current_facebook_page();

        if (!$facebook_active_page || ref $facebook_active_page ne 'HASH') {
            $facebook_active_page = {
                name    => $c->stash->{politician}->user->organization_chatbot->name,
                id      => $c->stash->{politician}->user->organization_chatbot->fb_config->page_id,
                picture => $c->stash->{politician}->user->organization_chatbot->picture
            }
        }
    }

    my $votolegal_integration = $c->stash->{politician}->has_votolegal_integration ? $c->stash->{politician}->get_votolegal_integration : undef ;

    my $has_movement = $c->stash->{politician}->movement ? 1 : 0;

    my $user         = $c->stash->{politician}->user;
    # Por enquanto um user só está em uma organização, mas posteriormente deverá ser informado o id da organização
    my $organization = $user->organization;
    my $chatbot      = $organization->chatbot;
    my $chatbot_id   = $chatbot ? $chatbot->id : undef;

    return $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $c->stash->{politician}->$_ } qw/
                name gender/ ),

            picture => $c->stash->{politician}->user->picture,

            picframe_url  => $c->stash->{politician}->share_url,
            picframe_text => $c->stash->{politician}->share_text,
            share_url     => $c->stash->{politician}->share_url,
            share_text    => $c->stash->{politician}->share_text,

            fb_page_id           => $c->stash->{politician}->user->organization_chatbot->fb_config ? $c->stash->{politician}->user->organization_chatbot->fb_config->page_id : undef,
            fb_page_access_token => $facebook_active_page ? $c->stash->{politician}->user->organization_chatbot->fb_config->access_token : undef,

            ( $has_movement ? ( movement => { map { $_ => $c->stash->{politician}->movement->$_ } qw/name id/  } ) : () ),

            ( state => { map { $_ => $c->stash->{politician}->address_state->$_ } qw/name code id/  } ),

            ( city => {map { $_ => $c->stash->{politician}->address_city->$_ } qw/name id/}  ),

            ( $c->stash->{politician}->party ? ( party => { map { $_ => $c->stash->{politician}->party->$_ } qw/acronym name id/ } ) : ( ) ),

            ( $c->stash->{politician}->office ? ( office => { map { $_ => $c->stash->{politician}->office->$_ } qw/id name/ } ) : ( ) ),

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
                    } $c->model("DB::PoliticianContact")->search( { organization_chatbot_id => $chatbot_id } )
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
                        { organization_chatbot_id => $chatbot_id },
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
            ),

            # Novos dados
            (
                organization => {
                    name             => $organization->name,
                    picture          => $organization->picture,
                    premium          => $organization->premium,
                    is_mandatoaberto => $organization->is_mandatoaberto,
                    has_ticket       => $organization->has_ticket,

                    has_email_broadcast => $organization->has_email_broadcast,
                    fb_app_id           => $organization->fb_app_id,

                    (
                        $chatbot ?
                        (
                            chatbot => {
                                name    => $chatbot->name,
                                picture => $chatbot->picture
                            }
                        ): ( )
                    )
                }
            ),
            (
                premium => $organization->premium
            ),
        }
    );
}

sub result_PUT { }

sub _upload_picture {
    my ( $self, $upload ) = @_;

    my $mimetype = mimetype( $upload->tempname );
    my $tempname = $upload->tempname;

    die \['file', 'invalid']       unless $mimetype =~ m/^image/;
    die \['picture', 'empty file'] unless $upload->size > 0;

    my $ret = $self->_drive->upload_file( tempname => $tempname );

    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;
