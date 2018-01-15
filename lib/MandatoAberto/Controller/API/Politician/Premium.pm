package MandatoAberto::Controller::API::Politician::Premium;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/admin/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('premium') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : CaptureArgs(0) { }

sub list_POST {
    my ($self, $c) = @_;

    # Posteriormente será implementado um método de pagamento
    # e a renovação/contratação do serviço premium
    # será automatizada

    
}

__PACKAGE__->meta->make_immutable;

1;