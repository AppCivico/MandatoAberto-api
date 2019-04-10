package MandatoAberto::Controller::API::Chatbot::Politician::Group;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('group') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Group')->search( { organization_chatbot_id => $c->stash->{politician}->user->organization_chatbot_id } );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $group_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $group_id } );

    my $group = $c->stash->{collection}->find($group_id);
    $c->detach("/error_404") unless ref $group;

    $c->stash->{group} = $group;
}

__PACKAGE__->meta->make_immutable;

1;
