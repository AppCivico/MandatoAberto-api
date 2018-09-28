package MandatoAberto::Controller::API::Chatbot::Entity;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianEntity",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('intents') : CaptureArgs(0) { }

sub list_available : Chained('base') : PathPart('available') : Args(0) : ActionClass('REST') { }

sub list_available_GET {
    my ($self, $c) = @_;

	my $page_id = $c->req->params->{fb_page_id};
	die \["fb_page_id", "missing"] unless $page_id;

	my $politician = $c->model("DB::Politician")->search( { fb_page_id => $page_id } )->next;
	die \['fb_page_id', 'could not find politician with that fb_page_id'] unless $politician;

    my $page    = $c->req->params->{page} || 1;
    my $results = 11;

    return $self->status_ok(
        $c,
        entity => {
            intents => [
                map {
                    my $e = $_;

                    if ( $e->has_active_knowledge_base ) {
					    +{
                            id         => $e->id,
                            name       => $e->name,
                            human_name => $e->human_name
					    }
                    }
                    else { }
                } $c->stash->{collection}->search(
                    { politician_id => $politician->id },
                    { page => $page, rows => $results }
                  )->all()
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;