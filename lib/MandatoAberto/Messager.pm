package MandatoAberto::Messager;
use common::sense;
use Moose;

use Furl;

use MandatoAberto::Utils;

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
    my ($self, $content) = @_;

    my $furl = Furl->new();

    # TODO complementar URL
    my $url = '';

    if (is_test()) {
        return 1;
    }

    $furl->post($url, $content);

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
