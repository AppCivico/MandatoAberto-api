package MandatoAberto::Messager;
use common::sense;
use Moose;

use Furl;

use MandatoAberto::Utils;

has fb_api_url => {
    is       => "rw",
    isa      => "Str",
    required => 1,
};

has _transport => (
    is         => "ro",
    lazy_build => 1,
);


sub send {
    my ($self, $content, $recipient_fb_id) = @_;

    my $furl = Furl->new();

    my $url = $ENV{fb_api_url};

    if (is_test()) {
        return 1;
    }

    my $json = encode_json {
        recipient => { id   => $recipient_fb_id },
        message   => { text => $content },
    };

    $furl->post($url, $json)

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
