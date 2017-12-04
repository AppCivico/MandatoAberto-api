package MandatoAberto::Messager::Template;
use Moose;
use namespace::autoclean;

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

    my $facebook_message = encode_json {
        recipient => { id   => $self->to },
        message   => { text => $self->message },
    };

    return $facebook_message;
}

__PACKAGE__->meta->make_immutable;

1;

