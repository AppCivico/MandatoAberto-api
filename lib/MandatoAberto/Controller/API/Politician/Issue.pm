package MandatoAberto::Controller::API::Politician::Issue;
use Moose;
use namespace::autoclean;

use WebService::Facebook;

use File::Basename;
use File::MimeInfo;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";

has _facebook => (
    is         => "ro",
    isa        => "WebService::Facebook",
    lazy_build => 1,
);

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Issue",

    # AutoListGET
    list_key  => "issues",

    # AutoResultPUT.
    object_key                => "issue",
    result_put_for            => "update",
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        my $ignore_flag = $c->req->params->{ignore} || 0;
        $params->{ignore} = $ignore_flag;

        $params->{open} = 0;

        if ($c->req->params->{groups}) {
            $c->req->params->{groups} =~ s/(\[|\]|(\s))//g;

            my @groups = split(',', $c->req->params->{groups});

            $params->{groups} = \@groups;
        } else {
            $params->{groups} = [];
        }

        # Tratando resposta por mídia
        my $file;
        if ( my $upload = $c->req->upload('file') ) {
            die \['reply', 'must not be send with file'] if $c->req->params->{reply};
            my $page_access_token = $c->stash->{politician}->fb_page_access_token;

            $file = $self->_upload_picture($upload, $page_access_token);
            $params->{saved_attachment_id}   = $file->{attachment_id};
            $params->{saved_attachment_type} = $file->{attachment_type};
        }

        return $params;
    },

    # AutoResultGET
    build_row => sub {
        return { $_[0]->get_columns() };
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

sub base : Chained('root') : PathPart('issue') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $issue_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $issue_id } );

    my $issue = $c->stash->{collection}->find($issue_id);
    $c->detach("/error_404") unless ref $issue;

    $c->stash->{issue} = $issue;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $filter = $c->req->params->{filter};
    die \['filter', 'missing'] unless $filter;
    die \['filter', 'invalid'] unless $filter =~ m/^(open|closed|ignored)$/;

    my $cond;
    if ( $filter eq 'open' ) {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 1,
            'me.message'       => { '!=' => 'Participar' }
        }
    }
    elsif ( $filter eq 'ignored' ) {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 0,
            reply              => \'IS NULL',
            'me.message'       => { '!=' => 'Participar' }
        }
    }
    else {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 0,
            reply              => \'IS NOT NULL',
            'me.message'       => { '!=' => 'Participar' }
        }
    }

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 1000;

    return $self->status_ok(
        $c,
        entity => {
            issues => [
                map {
                    my $i = $_;

                    my $reply = $i->reply;
                    my $open  = $i->open;

                    my ( $ignored_flag, $replied_flag );
                    if ( !$open && !$reply ) {
                        $ignored_flag = 1;
                        $replied_flag = 0;
                    }
                    elsif ( !$open && $reply ) {
                        $ignored_flag = 0;
                        $replied_flag = 1;
                    }
                    else {
                        $ignored_flag = 0;
                        $replied_flag = 0;
                    }

                    {
                        id           => $i->get_column('id'),
                        reply        => $i->get_column('reply'),
                        open         => $i->get_column('open'),
                        ignored      => $ignored_flag,
                        replied      => $replied_flag,
                        message      => $i->get_column('message'),
                        created_at   => $i->get_column('created_at'),
                        recipient    => {
                            id              => $i->get_column('recipient_id'),
                            name            => $i->recipient->get_column('name'),
                            profile_picture => $i->recipient->get_column('picture'),

                            groups => [
                                map {
                                    {
                                        id               => $_->id,
                                        name             => $_->get_column('name'),
                                        recipients_count => $_->get_column('recipients_count'),
                                        status           => $_->get_column('status'),
                                    }
                                } $i->recipient->groups_rs->all()
                            ]
                        },
                        intents => [
                            map {
                                {
                                    id   => $_->id,
                                    tag  => $_->human_name,
                                    has_active_knowledge_base => $_->has_active_knowledge_base
                                }
                            } $i->entity_rs->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    $cond,
                    {
                        prefetch => 'recipient',
                        page     => $page,
                        rows     => $results,
                        order_by => { '-desc' => 'me.created_at' }
                    }
                  )->all()
            ]
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET {
    my ($self, $c) = @_;

    my $issue     = $c->stash->{issue};
    my $recipient = $c->stash->{issue}->recipient;

    my $reply = $issue->reply;
    my $open  = $issue->open;

    my ( $ignored_flag, $replied_flag );
    if ( !$open && !$reply ) {
        $ignored_flag = 1;
        $replied_flag = 0;
    }
    elsif ( !$open && $reply ) {
        $ignored_flag = 0;
        $replied_flag = 1;
    }
    else {
        $ignored_flag = 0;
        $replied_flag = 0;
    }

    return $self->status_ok(
        $c,
        entity => {
            id         => $issue->id,
            reply      => $issue->reply,
            open       => $issue->open,
            message    => $issue->message,
            created_at => $issue->created_at,
            ignored    => $ignored_flag,
            replied    => $replied_flag,
            recipient  => {
                id              => $recipient->id,
                name            => $recipient->name,
                profile_picture => $recipient->picture,

                groups => [
                    map {
                        {
                            id               => $_->id,
                            name             => $_->get_column('name'),
                            recipients_count => $_->get_column('recipients_count'),
                            status           => $_->get_column('status'),
                        }
                    } $recipient->groups_rs->all()
                ]
            },
            intents => [
                map {
                    {
                        id  => $_->id,
                        tag => $_->human_name,
                        has_active_knowledge_base => $_->has_active_knowledge_base
                    }
                } $issue->entity_rs->all()
            ]
        }
    );
}

sub batch_ignore : Chained('base') : PathPart('batch-ignore') : Args(0) : ActionClass('REST') { }

sub batch_ignore_PUT {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { politician_id => $c->stash->{politician}->id } );

    my $ids = $c->req->params->{ids};
    die \['ids', 'missing'] unless $ids;
    # use DDP; p $ids;
    $c->stash->{collection}->execute(
        $c,
        for  => 'batch_ignore',
        with => {
            politician_id => $c->stash->{politician}->id,
            ids           => $ids
        }
    );

    return $self->status_ok(
        $c,
        entity => {

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

    die \[ 'picture', 'empty file' ]    unless $upload->size > 0;

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