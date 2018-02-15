package WebService::HttpCallback::Async;
use common::sense;
use MooseX::Singleton;

use HTTP::Async;
use JSON::MaybeXS;
use MandatoAberto::Utils;
use Encode qw(encode_utf8);

has _async => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build__async { HTTP::Async->new(slots => 10, timeout => 20) }

sub add {
    my ($self, %opts) = @_;

    if (is_test()) {
        $MandatoAberto::Test::Further::http_callback = \%opts;
        return int(rand(1000));
    }

    return $self->_async->add(
        HTTP::Request->new(
            POST => get_mandatoaberto_httpcb_url_for('/schedule'),
            ['Content-Type' => 'application/json; charset=UTF-8'],
            encode_utf8(encode_json(\%opts)),
        ),
    );
}

sub wait_all_responses {
    my ($self) = @_;

    while ($self->_async->not_empty()) {
        $self->_async->wait_for_next_response();
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
