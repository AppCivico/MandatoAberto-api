package MandatoAberto::Controller::API::Organization;
use common::sense;
use Moose;
use namespace::autoclean;

use WebService::GoogleDrive;

use File::Basename;
use File::MimeInfo;
use DateTime;
use Crypt::PRNG qw(random_string);

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

has _drive => (
    is         => "ro",
    isa        => "WebService::GoogleDrive",
    lazy_build => 1,
);

sub _build__drive { WebService::GoogleDrive->instance }

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('organization') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Organization');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $organization_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $organization_id } );

    my $organization = $c->stash->{collection}->find($organization_id);
    $c->detach("/error_404") unless ref $organization;

    # Verifico se o usuário faz parte da organização
    $c->stash->{is_me}        = $organization->users->search( { user_id => $c->user->id } )->count;
    $c->stash->{organization} = $organization;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result_GET {
    my ($self, $c) = @_;

    my $organization = $c->stash->{organization};

    return $self->status_ok(
        $c,
        entity => {
            # Dados da organização
            ( map { $_ => $organization->$_ } qw( id name premium premium_updated_at approved approved_at picture invite_token created_at updated_at ) ),

            # Chatbots
            ( chatbots => $organization->chatbots_for_get )
        }
    );
}

sub result_PUT {
    my ( $self, $c ) = @_;

    if ( my $upload = $c->req->upload("file") ) {
        my $picture_url = $self->_upload_picture($upload);

        $c->req->params->{picture} = $picture_url;
        print STDERR "picture_url: $picture_url\n";
    }

    my $organization = $c->stash->{organization}->execute(
        $c,
        for  => 'update',
        with => $c->req->params
    );

    return $self->status_ok(
        $c,
        entity => { id => $organization->id }
    );
}

sub _upload_picture {
    my ( $self, $upload ) = @_;

    my $mimetype = mimetype( $upload->tempname );
    my $tempname = $upload->tempname;

    die \['file', 'invalid']       unless $mimetype =~ m/^image/;
    die \['picture', 'empty file'] unless $upload->size > 0;

    my $ret = $self->_drive->upload_file( tempname => $tempname );
    print STDERR "\nret method: $ret\n"

    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;
