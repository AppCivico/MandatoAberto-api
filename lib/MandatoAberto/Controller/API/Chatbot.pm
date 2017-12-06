package MandatoAberto::Controller::API::Chatbot;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('chatbot') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/chatbot/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

__PACKAGE__->meta->make_immutable;

1;