package MandatoAberto::Controller::Organization;
use Mojo::Base 'MandatoAberto::Controller';

use Moose;

use WebService::GoogleDrive;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

has _drive => (
	is         => "ro",
	isa        => "WebService::GoogleDrive",
	lazy_build => 1,
);

sub _build__drive { WebService::GoogleDrive->instance }

sub load {
	my $c = shift;

	my $organization_id = $c->param('organization_id');

	my $organization = $c->schema->resultset('Organization')->search( { 'me.id' => $organization_id } )->next;
	if (!ref $organization) {
		$c->reply_not_found;
		$c->detach();
	}

	$c->stash(organization => $organization);

    # Verificando se o usuário faz parte da organização
	if ( !$c->current_user || $organization->users->search( { 'me.user_id' => $c->current_user->id } )->count == 0 ) {
		$c->reply_forbidden();
		$c->detach;
	}

	return $c;
}

sub get {
    my $c = shift;

    my $organization = $c->stash('organization');

    return $c->render(
        status => 200,
        json   => {
            # Dados da organização
            ( map { $_ => $organization->$_ } qw( id name premium premium_updated_at approved approved_at picture invite_token created_at updated_at ) ),

            # Chatbots
            ( chatbots => $organization->chatbots_for_get )
        }
    );
}

sub put {
    my $c = shift;

    my $upload = $c->param('picture');

	if ( ref $upload ) {
		my $picture_url = $c->_upload_picture($upload);

		$c->req->params->merge(
            picture => $picture_url
        );
	}

	my $organization = $c->stash->{organization}->execute(
		$c,
		for  => 'update',
		with => $c->req->params->to_hash
	);

    return $c->render(
        status => 202,
        json   => {
            id => $organization->id
        }
    );
}

sub _upload_picture {
	my ( $c, $upload ) = @_;

	my $mimetype = mimetype( $upload->filename );
	my $tempname = $upload->filename;

	die \['file', 'invalid']       unless $mimetype =~ m/^image/;
	die \['picture', 'empty file'] unless $upload->size > 0;

	my $ret = $c->_drive->upload_file( tempname => $tempname );

	return $ret;
}

1;
