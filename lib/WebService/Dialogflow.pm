package WebService::Dialogflow;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use MandatoAberto::Utils;

has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new( { headers => [ 'Authorization', $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN} ] } ) }

sub get_entities {
    my ( $self, %opts ) = @_;

    die \['DIALOGFLOW_DEVELOPER_ACCESS_TOKEN', 'missing'] unless $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN};

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . '/v2/projects/mandato-aberto/agent/entityTypes';
                $res = $self->furl->get( $url );

                die $res->decoded_content unless $res->is_success;
            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        $res = decode_json( $res->decoded_content );
    }

    return $res;
}

1;
