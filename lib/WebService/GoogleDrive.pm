package WebService::GoogleDrive;
use common::sense;
use MooseX::Singleton;

use Net::Google::Drive;

use MandatoAberto::Utils;

has 'drive' => ( is => 'rw', lazy => 1, builder => '_build_drive' );

sub _build_drive {
    Net::Google::Drive->new(
        -client_id      => '737899973087-bahrvtg3d7e0mpd06ibt7cul8qrkre1l.apps.googleusercontent.com',
        -client_secret  => 'rpYs0h1oaSAHI0rqRC6maFtS',
        -access_token   => 'ya29.GlufBqM9DuuMwAXAyQspVUfeGHgbfx-6s655Uf8E-Rjw2T2m43Idka0HiHt8w3db96ozs9MSDmFz4vROu5ZircVZfv5Rvtd-N_de3sodvhodLrNt_KUjpyzTPiD3',
        -refresh_token  => '1/7cbS8jY2U7_Onn7figWoO37YXi8VHL-v9T2PzURtrCIilPysk0YCAoXPwxCv8pq2',
    );
}

sub upload_file {
    my ( $self, %opts ) = @_;

    my @required_opts = qw( tempname );
    defined $opts{$_} or die "missing $_" for @required_opts;

    my $res;
    if (is_test()) {
        $res = 'www.google.com';
    }
    else {
        my $res = $self->_drive->uploadFile( -source_file => $opts{tempname} );
        die 'upload fail' unless $res->{id};

        $res = $self->_drive->getFileMetadata( -file_id => $res->{id} );
        $res = $res->{embedLink}
    }

    return $res;
}

1;
