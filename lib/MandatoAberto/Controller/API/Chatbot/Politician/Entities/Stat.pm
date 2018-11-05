package MandatoAberto::Controller::API::Chatbot::Politician::Entities::Stat;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/politician/entities/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('stats') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::PoliticianEntityStat');
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST {
    my ($self, $c) = @_;

    my $stats = $c->stash->{collection}->execute(
        $c,
        for  => 'create',
        with => {
            %{ $c->req->params },
            politician_entity_id => $c->stash->{entity}->id
        }
    );

	return $self->status_created(
		$c,
		location => $c->uri_for($c->controller('API::Chatbot::Politician::Entities::Stat'), $stats->recipient_id),
		entity   => { success => 1 }
	);
}

__PACKAGE__->meta->make_immutable;

1;