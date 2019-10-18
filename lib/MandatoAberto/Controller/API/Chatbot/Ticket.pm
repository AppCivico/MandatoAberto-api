package MandatoAberto::Controller::API::Chatbot::Ticket;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw/ is_test /;
use MandatoAberto::Uploader;

use File::Basename;
use File::MimeInfo;
use Crypt::PRNG qw(random_string);
use DateTime;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

has uploader => (
    is      => "ro",
    isa     => "MandatoAberto::Uploader",
    default => sub { MandatoAberto::Uploader->new() },
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('ticket') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $ticket_id) = @_;

    $c->stash->{collection} = $c->model('DB::Ticket')->search_rs( { id => $ticket_id } );

    my $ticket = $c->stash->{collection}->find($ticket_id);
    $c->detach("/error_404") unless ref $ticket;

    $c->stash->{ticket} = $ticket;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $rs = $c->model('DB::Ticket');

    if ($c->req->params->{message} && ref $c->req->params->{message} ne 'ARRAY') {
        $c->req->params->{message} = [$c->req->params->{message}];
    }

    my $uploads = $c->req->params;
    my @attachments;
    for my $upload_key (keys %$uploads) {
        next unless $upload_key =~ /^ticket_attachment/;

        my $upload = $uploads->{$upload_key};
        # $upload    = $self->_upload_file($upload);

        push @attachments, {
            attached_to_message => 0,
            type                => undef,
            url                 => $upload
        };
    }
    $c->req->params->{ticket_attachments} = \@attachments;

    my $ticket = $rs->execute(
        $c,
        for  => 'create',
        with => $c->req->params
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller('API::Chatbot::Ticket'), $ticket->id),
        entity   => { id => $ticket->id }
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $fb_id = $c->req->params->{fb_id} or die \['fb_id', 'missing'];

    my $rs = $c->model('DB::Ticket')->search_rs(
        { 'recipient.fb_id' => $fb_id },
        { join => 'recipient' }
    );

    return $self->status_ok(
        $c,
        entity   => $rs->build_list
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT {
    my ($self, $c) = @_;

    if ( $c->req->params->{status} ) {
        die \['status', 'invalid'] unless $c->req->params->{status} eq 'canceled';
    }

    my $uploads = $c->req->params;
    my @attachments;
    for my $upload_key (keys %$uploads) {
        next unless $upload_key =~ /^ticket_attachment/;

        my $upload = $uploads->{$upload_key};
        # $upload    = $self->_upload_file($upload);

        push @attachments, {
            attached_to_message => 0,
            type                => undef,
            url                 => $upload
        };
    }

    my $ticket = $c->stash->{ticket}->execute(
        $c,
        for  => 'update',
        with => {
            message            => $c->req->params->{message},
            status             => $c->req->params->{status},
            ticket_attachments => \@attachments,
            updated_by_chatbot => 1,
        }
    );

    return $self->status_ok(
        $c,
        entity => { id => $ticket->id }
    )
}

sub _upload_file {
    my ( $self, $upload ) = @_;

    my $mimetype = mimetype( $upload->tempname );
    my $tempname = $upload->tempname;

    die \[ 'picture', 'empty file' ] unless $upload->size > 0;

    my $path = "votolegal/picture/" . random_string(3) . "/"  . DateTime->now->epoch . basename($tempname);

    my $url = $self->uploader->upload(
        {
            path => $path,
            file => $tempname,
            type => $mimetype,
        }
    );

    return {
        url => $url->as_string,
        type => $mimetype
    }
}

__PACKAGE__->meta->make_immutable;

1;
