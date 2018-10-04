package MandatoAberto::Controller::Politician::DirectMessage;
use Mojo::Base 'Mojolicious::Controller';
use Moose;

use WebService::Facebook;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

sub post {
    my $c = shift;

    die \['premium', 'politician is not premium'] unless $c->stash->{politician}->premium;

    my $groups;
    if ( my $group_param = $c->req->params->to_hash->{groups} ) {
		$group_param =~ s/(\[|\]|(\s))//g;

		my @groups = split(',', $group_param);

		$groups = \@groups;
    }
    else {
        $groups = [];
    }

	# Por agora, por padrão o type será text
	my $type = $c->req->params->to_hash->{type} || 'text';

    my $file;
    if ( $type eq 'attachment' ) {
        die \['attachment_type', 'missing'] unless $c->req->params->to_hash->{attachment_type};

        my $page_access_token = $c->stash->{politician}->fb_page_access_token;
        if ( my $upload = $c->req->upload("file") ) {

            $file = $c->upload_picture($upload, $page_access_token);
            $c->req->params->to_hash->{saved_attachment_id} = $file->{attachment_id};
            $c->req->params->to_hash->{attachment_type}     = $file->{attachment_type};
        }

        $c->req->params->to_hash->{attachment_type} ne 'template' ? () :
          die \['attachment_template', 'missing'] unless $c->req->params->to_hash->{attachment_template};
    }

	my $direct_message = $c->schema->resultset('DirectMessage')->execute(
		$c,
		for  => "create",
		with => {
			politician_id       => $c->stash->{politician}->id,
			groups              => $groups,
			content             => $c->req->params->to_hash->{content},
			name                => $c->req->params->to_hash->{name},
			type                => $type,
			attachment_type     => $c->req->params->to_hash->{attachment_type},
			attachment_template => $c->req->params->to_hash->{attachment_template},
			saved_attachment_id => $c->req->params->to_hash->{saved_attachment_id},
		},
	);

    return $c->render(
        json => {
            id => $direct_message->id
        },
        status => 201,
    );
}

sub get {
    my $c = shift;
    use DDP;
    my $politician_id = $c->stash->{politician}->id;

	my $page    = $c->req->params->to_hash->{page}    || 1;
	my $results = $c->req->params->to_hash->{results} || 10;

	return $c->render(
		json => {
			direct_messages => [
                map {
                    my $dm = $_;

                    +{
                        campaign_id         => $dm->get_column('campaign_id'),
                        content             => $dm->get_column('content') ? $dm->get_column('content') : '(Campanha realizada com mídia de imagem ou áudio)',
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
                } $c->schema->resultset('DirectMessage')->search(
                    { politician_id => $politician_id },
                    {
                        page => $page,
                        rows => $results
                    }
                )->all()
            ]
		},
		status => 200,
	);
}

sub upload_picture {
    my ( $c, $upload, $page_access_token ) = @_;

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

    my $facebook = WebService::Facebook->instance;

    my $asset = $facebook->save_asset(
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

1;
