package MandatoAberto::Controller::API::Chatbot::Politician::Entities;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('intents') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::PoliticianEntity')->search( { politician_id => $c->stash->{politician}->id } );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
	my ($self, $c, $entity_id) = @_;

	$c->stash->{collection} = $c->stash->{collection}->search( { id => $entity_id } );

	my $entity = $c->stash->{collection}->find($entity_id);
	$c->detach("/error_404") unless ref $entity;

	$c->stash->{entity} = $entity;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::ViewAvailableEntities');

	my $page_id = $c->req->params->{fb_page_id};
	die \["fb_page_id", "missing"] unless $page_id;

	my $politician = $c->model("DB::Politician")->search( { fb_page_id => $page_id } )->next;
	die \['fb_page_id', 'could not find politician with that fb_page_id'] unless $politician;

    return $self->status_ok(
        $c,
        entity => {
            intents => [
                map {
                    my $e = $_;

                    +{
                        id         => $e->id,
                        name       => $e->name,
                        human_name => $e->human_name
                    }
                } $c->stash->{collection}->search(
                    undef,
                    { bind => [ $politician->user_id, $politician->user_id ] }
                  )->all()
            ]
        }
    )
}

sub list_available : Chained('base') : PathPart('available') : Args(0) : ActionClass('REST') { }

sub list_available_GET {
    my ($self, $c) = @_;

	$c->stash->{collection} = $c->model('DB::ViewAvailableEntities');

    my $page_id = $c->req->params->{fb_page_id};
    die \["fb_page_id", "missing"] unless $page_id;

    my $politician = $c->model("DB::Politician")->search( { fb_page_id => $page_id } )->next;
    die \['fb_page_id', 'could not find politician with that fb_page_id'] unless $politician;

    my $page    = $c->req->params->{page} || 1;
    my $results = 10;

    return $self->status_ok(
        $c,
        entity => {
            intents => [
                map {
                    my $e = $_;

                    +{
                        id         => $e->id,
                        name       => $e->name,
                        human_name => $e->human_name
                    }
                } $c->stash->{collection}->search(
                    undef,
                    {
                        bind => [ $politician->user_id, $politician->user_id ],
                        page => $page,
                        rows => $results
                    }
                  )->all()
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;