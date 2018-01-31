package WebService::HttpCallback;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use MandatoAberto::Utils;


has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new }

sub send_message {
    my ( $self, %opts ) = @_;

    if (is_test()) {
        $MandatoAberto::Test::Further::http_callback = \%opts;

        return { id => rand(10000) };
    }
    else {
        my $res;
        eval {
            retry {
                $res = $self->furl->post( get_mandatoaberto_httpcb_url_for('/schedule'), [], [%opts] );
                use DDP; p $res;
                die $res->decoded_content unless $res->is_success;
            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        return decode_json( $res->decoded_content );
    }
}

1;