package MandatoAberto::Controller::API::Politician::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;

use WebService::Facebook;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

has _facebook => (
	is         => "ro",
	isa        => "WebService::Facebook",
	lazy_build => 1,
);

__PACKAGE__->config(
    # AutoBase.
    result => "DB::DirectMessage",

    list_key  => "direct_messages",
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

sub base : Chained('root') : PathPart('direct-message') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    die \['premium', 'politician is not premium'] unless $c->stash->{politician}->premium;

    my $groups;
    if ($c->req->params->{groups}) {
        $c->req->params->{groups} =~ s/(\[|\]|(\s))//g;

        my @groups = split(',', $c->req->params->{groups});

        $groups = \@groups;
    } else {
        $groups = [];
    }

    # Por agora, por padrão o type será text
    my $type = $c->req->params->{type} || 'text';

    my $file;
    if ( $type eq 'attachment' ) {
        die \['attachment_type', 'missing'] unless $c->req->params->{attachment_type};

        my $page_access_token = $c->stash->{politician}->fb_page_access_token;

        if ( my $upload = $c->req->upload("file") ) {
            $file = $self->_upload_picture($upload, $page_access_token);
			$c->req->params->{saved_attachment_id} = $file->{attachment_id};
			$c->req->params->{attachment_type}     = $file->{attachment_type};
        }

        $c->req->params->{attachment_type} ne 'template' ? () :
          die \['attachment_template', 'missing'] unless $c->req->params->{attachment_template};
    }

    my $direct_message = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            politician_id       => $c->stash->{politician}->id,
            groups              => $groups,
            content             => $c->req->params->{content},
            name                => $c->req->params->{name},
            type                => $type,
            attachment_type     => $c->req->params->{attachment_type},
            attachment_template => $c->req->params->{attachment_template},
            saved_attachment_id => $c->req->params->{saved_attachment_id},
        },
    );

    my $politician_name = $c->stash->{politician}->name;

    $c->slack_notify("O usuário ${\($politician_name)} disparou uma campanha para ${\($direct_message->count)} recipiente(s)") unless is_test();

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Politician::DirectMessage")->action_for('result'), [ $direct_message->id ]),
        entity   => { id => $direct_message->id }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 1000;

    return $self->status_ok(
        $c,
        entity => {
            direct_messages => [
                map {
                    my $dm = $_;

                    +{
                        campaign_id         => $dm->get_column('campaign_id'),
                        content             => $dm->get_column('content'),
                        created_at          => $dm->get_column('created_at'),
                        name                => $dm->get_column('name'),
                        saved_attachment_id => $dm->get_column('saved_attachment_id'),
                        count               => $dm->get_column('count'),
                        groups      => [
                            map {
                                my $g = $_;

                                {
                                    id   => $g->get_column('id'),
                                    name => $g->get_column('name')
                                }
                            } $dm->groups_rs->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { politician_id => $politician_id },
                    {
                        page => $page,
                        rows => $results
                    }
                )->all()
            ]
        }
    );
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
