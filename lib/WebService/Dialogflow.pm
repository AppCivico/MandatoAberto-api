package WebService::Dialogflow;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use File::Temp;

use MandatoAberto::Utils;

has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new() }

sub generate_access_token {
    my ($self, %opts) = @_;

    my $project = $opts{project};
    die 'project missing' unless $project;

	my $tmp_file      = File::Temp->new( DIR => '/tmp/', SUFFIX => '.json' );
	my $tmp_file_name = $tmp_file->filename;
	print $tmp_file $project->credentials;

    my $access_token = `GOOGLE_APPLICATION_CREDENTIALS='$tmp_file_name'; gcloud auth application-default print-access-token`;
    die 'fail generating access token for dialogflow' unless $access_token;

    $access_token =~ s/\s+$//;

    return $access_token;
}

sub get_entities {
    my ( $self, %opts ) = @_;

    my $project = $opts{project};
    die 'project missing' unless $project;

    my $project_id = $project->project_id;

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token($project);

        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project_id/agent/entityTypes";
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

	my $project = $opts{project};
	die 'project missing' unless $project;

	my $project_id = $project->project_id;

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token( project => $project );

        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project_id/agent/intents";

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

sub create_intent {
    my ( $self, %opts ) = @_;

	my $project = $opts{project};
	die 'project missing' unless $project;

	my $project_id = $project->project_id;

    my $res;
    if (is_test()) {
        $res = $MandatoAberto::Test::Further::dialogflow_response;
    }
    else {
        my $access_token = $self->generate_access_token();

        eval {
            retry {
                my $url = $ENV{DIALOGFLOW_URL} . "/v2/projects/$project_id/agent/intents?languageCode=pt-BR";
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
