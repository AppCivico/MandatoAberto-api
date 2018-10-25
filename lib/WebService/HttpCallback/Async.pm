package WebService::HttpCallback::Async;
use common::sense;
use MooseX::Singleton;

use URI;
use HTTP::Async;
use JSON::MaybeXS;
use URI::QueryParam;
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

    my $uri = URI->new(get_mandatoaberto_httpcb_url_for('/schedule'));
    my @old = %opts;
    while (my ($k, $v) = splice(@old, 0, 2)) {
        $v = encode_utf8($v);

        $uri->query_param_append($k, $v);
    }

    my $res = $self->_async->add(
        HTTP::Request->new(
            POST => $uri->as_string,
        ),
    );

    use DDP;
    print STDERR "httpcb_res: $res";
    my $v = "httpcb_res: $res";
    p $v;
    return $res;
}

sub wait_for_all_responses {
    my ($self) = @_;

    while ($self->_async->not_empty()) {
        $self->_async->wait_for_next_response();
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
