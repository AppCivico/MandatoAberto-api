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
    my $whoami = `whoami`;
    print STDERR "\nwhoami: $whoami\n";

    my $access_token = `export GOOGLE_APPLICATION_CREDENTIALS='$ENV{GOOGLE_APPLICATION_CREDENTIALS}' && gcloud auth application-default print-access-token`;
    print STDERR $access_token;
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
                    [ 'Authorization', "Bearer $access_token" ]
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

    my $project = $opts{dialogflow_project_id};

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

                $res = $self->furl->get(
                    $url,
                    [ 'Authorization', 'Bearer ' . 'ya29.c.ElpkBlYg_Z-ihd-PiQQEi7x-n8FVljrhXoTcnDKKSfqGFPLWU9lcwNUZHVVjW_BmmQJByssuBATik8QrISNLkL9ObdYBR2LwaLCfyw45jan0n6gOJ-3i85qsdEI' ]
                );

				p $res->request;
				p $res->request->as_string;
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
                    [ 'Authorization', "Bearer $access_token" ]
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
