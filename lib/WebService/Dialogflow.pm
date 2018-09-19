package WebService::Dialogflow;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use MandatoAberto::Utils;

has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new() }

sub get_entities {
    my ( $self, %opts ) = @_;

    die \['DIALOGFLOW_DEVELOPER_ACCESS_TOKEN', 'missing'] unless $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN};

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/entityTypes";
                $res = $self->furl->get(
                    $url,
                    [ 'Authorization', $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN} ]
                );

                die $res->decoded_content unless $res->is_success;
            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        $res = decode_json( $res->decoded_content );
    }

    return $res;
}

sub get_intents {
    my ( $self, %opts ) = @_;

    die \['DIALOGFLOW_DEVELOPER_ACCESS_TOKEN', 'missing'] unless $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN};

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/intents";
                $res = $self->furl->get(
                    $url,
                    [ 'Authorization', $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN} ]
                );

                die $res->decoded_content unless $res->is_success;
            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        $res = decode_json( $res->decoded_content );
    }

    return $res;
}

sub create_intent {
    my ( $self, %opts ) = @_;

    die \['DIALOGFLOW_DEVELOPER_ACCESS_TOKEN', 'missing'] unless $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN};

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/intents?languageCode=pt-BR";
                $res = $self->furl->post(
                    $url,
                    [ 'Authorization', $ENV{DIALOGFLOW_DEVELOPER_ACCESS_TOKEN} ]
                );

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
