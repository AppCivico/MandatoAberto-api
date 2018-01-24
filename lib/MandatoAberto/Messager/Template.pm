package MandatoAberto::Messager::Template;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils;

use JSON::MaybeXS;

has to => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has message => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has vars => (
    is       => "ro",
    isa      => "HashRef",
    default  => sub { {} },
);

sub build_message {
    my ($self) = @_;

    my $httpcb_request = encode_json {
        url  => $ENV{FB_API_URL},
        body => {
            recipient => {
                id => $self->to
            },
            message => {
                text => $self->message,
                quick_replies => [
                    {
                        content_type => 'text',
                        title        => 'Voltar para o início',
                        payload      => 'greetings'
                    }
                ]
            }
        },
    };

    return $httpcb_request;
}

__PACKAGE__->meta->make_immutable;

1;

