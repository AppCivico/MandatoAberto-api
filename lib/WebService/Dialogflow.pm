package WebService::Dialogflow;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use MandatoAberto::Utils;

has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new() }

sub generate_access_token {
    my ($self) = @_;

    my $access_token = `gcloud auth application-default print-access-token`;
    die 'fail generating access token for dialogflow' unless $access_token;

    $access_token =~ s/\s+$//;

    return $access_token;
}

sub get_entities {
    my ( $self, %opts ) = @_;

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token();

        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/entityTypes";
                $res = $self->furl->get(
                    $url,
                    [ 'Authorization', $access_token ]
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

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token();
        use DDP; p $access_token;
        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/intents";
                p 'access_token dentro do eval: ' . $access_token;
                $res = $self->furl->get(
                    $url,
                    [ 'Authorization', $access_token ]
                );
                p $res->request->header;
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

    my $project = $ENV{DIALOGFLOW_PROJECT_NAME} || 'mandato-aberto';

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token();

        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project/agent/intents?languageCode=pt-BR";
                $res = $self->furl->post(
                    $url,
                    [ 'Authorization', $access_token ]
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
