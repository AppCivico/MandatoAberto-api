package MandatoAberto::Messager;
use common::sense;
use Moose;

use Furl;

use MandatoAberto::Utils;

BEGIN { $ENV{FB_API_URL} or die "missing env 'FB_API_URL'." }

has _transport => (
    is         => "ro",
    lazy_build => 1,
);

sub _build_transport {
    my $self = shift;

    return Furl->new(
        timeout => 10,
    );
}

sub send {
    my ($self, $content, $access_token) = @_;

    my $furl = Furl->new();

    my $url = $ENV{FB_API_URL} . '/me/messages?access_token=' . $access_token;

    if (is_test()) {
        return 1;
    }

    $furl->post(
        $url,
        [ 'Content-Type' => 'application/json' ],
        $content
    );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
