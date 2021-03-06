package WebService::GoogleDrive;
use common::sense;
use MooseX::Singleton;

use Net::Google::Drive;

use MandatoAberto::Utils;
use JSON;

has 'drive' => ( is => 'rw', lazy => 1, builder => '_build_drive' );

sub _build_drive {
    Net::Google::Drive->new(
        -client_id      => $ENV{DRIVE_CLIENT_ID},
        -client_secret  => $ENV{DRIVE_CLIENT_SECRET},
        -access_token   => $ENV{DRIVE_ACCESS_TOKEN},
        -refresh_token  => $ENV{DRIVE_REFRESH_TOKEN},
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
        $res = $self->drive->uploadFile( -source_file => $opts{tempname} );
        die 'upload fail' unless $res->{id};

        $self->drive->setFilePermission(
            -file_id => $res->{id},
            -type    => 'anyone',
            -role    => 'reader'
        );

        $res = 'https://drive.google.com/uc?id=' . $res->{id};
    }

    return $res;
}

1;
