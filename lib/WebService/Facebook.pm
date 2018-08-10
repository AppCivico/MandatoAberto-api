package WebService::Facebook;
use common::sense;
use MooseX::Singleton;

use JSON::MaybeXS;
use Furl;
use Try::Tiny::Retry;
use MandatoAberto::Utils;

has 'furl' => ( is => 'rw', lazy => 1, builder => '_build_furl' );

sub _build_furl { Furl->new( { headers => ['Content-Type', 'application/json'] } ) }

sub upload_picture {
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
                my $url = $ENV{FB_API_URL} . '/me/message_attachments?access_token' . $opts{access_token};
                $res = $self->furl->post(
                    $url,
                    [ 'Content-Type', 'form-data' ],
                    [
                        encode_json(
                            message => {
                                attachment => {
                                    type    => 'image',
                                    payload => { is_reusable => \1 }
                                }
                            },
                        ),
                        "filedata=$opts{image_path};type=$opts{image_extension}"
                    ],
                );

                die $res->decoded_content unless $res->is_success;
            }
            retry_if { shift() < 3 } catch { die $_; };
        };
        die $@ if $@;

        return decode_json( $res->decoded_content );
    }
}

1;
