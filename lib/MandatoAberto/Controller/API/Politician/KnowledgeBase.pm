package MandatoAberto::Controller::API::Politician::KnowledgeBase;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoListPOST';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultPUT';
with 'CatalystX::Eta::Controller::AutoResultGET';

use WebService::Facebook;

use File::Basename;
use File::MimeInfo;


has _facebook => (
    is         => "ro",
    isa        => "WebService::Facebook",
    lazy_build => 1,
);

__PACKAGE__->config(
    # AutoBase
    result  => 'DB::PoliticianKnowledgeBase',
    no_user => 1,

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->stash->{politician}->id;

        my $entity_id = $c->req->params->{entity_id};
        die \['entity_id', 'missing'] unless $entity_id;

        my $file;
        if ( my $upload = $c->req->upload("file") ) {
            my $page_access_token = $c->stash->{politician}->fb_page_access_token;

            $file = $self->_upload_picture($upload, $page_access_token);

            $params->{saved_attachment_id}   = $file->{attachment_id};
            $params->{saved_attachment_type} = $file->{attachment_type};
        }

        $params->{entities} = [$entity_id];

        return $params;
    },

    # AutoObject
    object_verify_type => 'int',
    object_key         => 'politician_knowledge_base',

    # AutoResultPUT.
    result_put_for => 'update',
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        my $file;
        if ( my $upload = $c->req->upload('file') ) {
            my $page_access_token = $c->stash->{politician}->fb_page_access_token;

            $file = $self->_upload_picture($upload, $page_access_token);
            $params->{saved_attachment_id}   = $file->{attachment_id};
            $params->{saved_attachment_type} = $file->{attachment_type};
        }

        return $params;
    },

    # AutoResultGET
    build_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id                    => $r->id,
            active                => $r->active,
            answer                => $r->answer,
            updated_at            => $r->updated_at,
            created_at            => $r->created_at,
            saved_attachment_id   => $r->saved_attachment_id,
            saved_attachment_type => $r->saved_attachment_type,
            intents => [
                map {
                    {
                        id               => $_->id,
                        tag              => $_->human_name,
                        recipients_count => $_->recipient_count
                    }
                } $r->entity_rs->all()
            ]
        }
    },
);


sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('knowledge-base') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

sub result_PUT { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $filter = $c->req->params->{filter} || 'active';
    die \['filter', 'invalid'] unless $filter =~ /(active|inactive)/;

    my $cond;
    if ( $filter eq 'active' ) {
        $cond = {
            politician_id => $c->stash->{politician}->id,
            active        => 1
        };
    }
    elsif ( $filter eq 'inactive' ) {
        $cond = {
            politician_id => $c->stash->{politician}->id,
            active        => 0
        };
    }

    return $self->status_ok(
        $c,
        entity => {
            knowledge_base => [
                map {
                    my $kb = $_;

                    +{
                        id         => $kb->id,
                        answer     => $kb->answer,
                        created_at => $kb->created_at,
                        intents    => [
                            map {
                                {
                                    id               => $_->id,
                                    tag              => $_->human_name,
                                    recipients_count => $_->recipient_count
                                }
                            } $kb->entity_rs->all()
                        ]
                    }
                } $c->stash->{collection}->search( $cond )->all()
            ]
        }
    )
}

sub _upload_picture {
    my ( $self, $upload, $page_access_token ) = @_;

    my $mimetype = mimetype( $upload->tempname );
    my $tempname = $upload->tempname;

    my $attachment_type;
    if ( $mimetype =~ m/^image/ ) {
        $attachment_type = 'image'
    }
    elsif ( $mimetype =~ m/^video/ ) {
        $attachment_type = 'video'
    }
    elsif ( $mimetype =~ m/^audio/ ) {
        $attachment_type = 'audio'
    }
    else {
        $attachment_type = 'file'
    }

    die \[ 'picture', 'empty file' ] unless $upload->size > 0;

    my $asset = $self->_facebook->save_asset(
        access_token    => $page_access_token,
        attachment_type => $attachment_type,
        file            => $tempname,
        mimetype        => $mimetype
    );

    return {
        attachment_id   => $asset->{attachment_id},
        attachment_type => $attachment_type
    };
}

sub _build__facebook { WebService::Facebook->instance }

__PACKAGE__->meta->make_immutable;

1;