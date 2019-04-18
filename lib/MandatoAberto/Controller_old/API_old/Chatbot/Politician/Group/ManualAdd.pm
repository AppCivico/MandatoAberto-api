package MandatoAberto::Controller::API::Chatbot::Politician::Group::ManualAdd;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/politician/group/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('manual-add') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

	my $recipient = $c->model('DB::Recipient')->search( { fb_id => $c->req->params->{fb_id} } )->next;
	eval {$recipient->add_to_group($c->stash->{group}->id)};

    return $self->status_ok(
        $c,
        entity => { success => $@ ? 0 : 1 }
    );
}

__PACKAGE__->meta->make_immutable;

1;
