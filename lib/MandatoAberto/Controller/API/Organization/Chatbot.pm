package MandatoAberto::Controller::API::Organization::Chatbot;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/organization/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('chatbot') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::OrganizationChatbot')->search( { organization_id => $c->stash->{organization}->id } );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $chatbot_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { 'me.id' => $chatbot_id } );

    my $chatbot = $c->stash->{collection}->find($chatbot_id);
    $c->detach("/error_404") unless ref $chatbot;

    $c->stash->{chatbot} = $chatbot;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            chatbots => [
                map {
                   +{
                        id        => $_->id,
                        picture   => $_->picture,
                        name      => $_->name,
                        fb_config => $_->fb_config_for_GET
                    }
                } $c->stash->{collection}->all()
            ]
        }
    )
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    my $chatbot = $c->stash->{chatbot};

    return $self->status_ok(
        $c,
        entity => {
            id        => $chatbot->id,
            picture   => $chatbot->picture,
            name      => $chatbot->name,
            fb_config => $chatbot->fb_config_for_GET
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;