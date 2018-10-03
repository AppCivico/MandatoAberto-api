package MandatoAberto::Controller::Politician::DirectMessage;
use Mojo::Base 'Mojolicious::Controller';

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

        # if ( my $upload = $c->req->upload("file") ) {
        #     $file = $self->_upload_picture($upload, $page_access_token);
        #     $c->req->params->to_hash->{saved_attachment_id} = $file->{attachment_id};
        #     $c->req->params->to_hash->{attachment_type}     = $file->{attachment_type};
        # }

        # $c->req->params->to_hash->{attachment_type} ne 'template' ? () :
        #   die \['attachment_template', 'missing'] unless $c->req->params->to_hash->{attachment_template};
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
    use DDP; p $direct_message;
    return $c->render(
        json => {
            ok => 1
        },
        status => 200,
    );
}

1;
