package WebService::Facebook;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use LWP::UserAgent;
use Try::Tiny::Retry;
use MandatoAberto::Utils;

has 'ua' => ( is => 'rw', lazy => 1, builder => '_build_ua' );

sub _build_ua { LWP::UserAgent->new() }

sub save_asset {
    my ( $self, %opts ) = @_;

    if (is_test()) {
        return {
            attachment_id => '1857777774821032'
        };
    }
    else {
        my $res;
        eval {
            retry {
                my $url = $ENV{FB_API_URL} . '/me/message_attachments?access_token=' . $opts{access_token};

                $res = $self->ua->post(
                    $url,
                    Content_Type => 'form-data',
                    Content => [
                        message => encode_json(
                            {
                                attachment => {
                                    type    => $opts{attachment_type},
                                    payload => {
                                        is_reusable => \1
                                    }
                                }
                            }
                        ),
                        filedata => [ $opts{file} ],
                        type     => $opts{mimetype}
                    ]
                );

                die $res->decoded_content unless $res->is_success;

                my $response = decode_json( $res->decoded_content );
                die \['file', 'invalid response'] unless $response->{attachment_id};

            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        return decode_json( $res->decoded_content );
    }
}

sub send_message {
    my ($self, %opts) = @_;

    if (is_test()) {
        return {
            attachment_id => '1857777774821032'
        };
    }
    else {
        my $res;
        eval {
            retry {
                my $url = $ENV{FB_API_URL} . '/me/messages?access_token=' . $opts{access_token};

                $res = $self->ua->post(
                    $url,
                    Content_Type => 'application/json',
                    Content      => $opts{content}
                );

                die $res->decoded_content unless $res->is_success;

                my $response = decode_json( $res->decoded_content );
                die 'invalid response' unless $response;

            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        return 1;
    }
}

1;
