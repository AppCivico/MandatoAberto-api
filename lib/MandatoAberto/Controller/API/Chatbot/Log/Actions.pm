package MandatoAberto::Controller::API::Chatbot::Log::Actions;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/log/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('actions') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $rs = $c->model('DB::LogAction');

    return $self->status_ok(
        $c,
        entity => {
            actions => [
                map {
                    +{
                        id        => $_->id,
                        name      => $_->name,
                        has_field => $_->has_field
                    }
                } $rs->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
