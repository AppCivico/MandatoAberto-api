package MandatoAberto::Controller::API::Chatbot::KnowledgeBase;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON;
use Encode;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('knowledge-base') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::PoliticianKnowledgeBase');
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \["politician_id", "missing"] unless $politician_id;

    my $fb_id        = $c->req->params->{fb_id};
    my $recipient_id = $c->req->params->{recipient_id};

    die \["fb_id", "missing"] unless $fb_id || $recipient_id;

    my $politician = $c->model('DB::Politician')->find($politician_id);

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            'me.organization_chatbot_id' => $politician->user->organization_chatbot_id,
            'me.active'                  => 1
        }
    );

    my $recipient = $politician->user->chatbot->recipients->search(
        {
            ( $fb_id ? (fb_id => $fb_id) : (id => $recipient_id) )
        }
    )->next
      or die \['fb_id', 'invalid'];

    my $entities = $c->req->params->{entities};
    die \['entities', 'missing'] unless $entities;
    my @entities_names;

    $entities = eval { decode_json( Encode::encode_utf8($entities) ) } || $entities;
    if ($@) {

        if ( $politician->user->organization_chatbot->politician_entities->entity_exists($entities) ) {
            $entities = lc $entities;
            push @entities_names, $entities;
        }
    }
    else {
        my @required_json_fields = qw (queryText intent);
        die \['entities', "missing 'queryResult' param"] unless $entities->{queryResult};

        for (@required_json_fields) {
            die \['entities', "missing '$_' param"] unless $entities->{queryResult}->{$_}
        }

        # TODO melhorar esse bloco
        my $entity_name = $entities->{queryResult}->{intent}->{displayName};
        $entity_name    = lc $entity_name;

        push @entities_names, $entity_name;
    }

    $c->stash->{collection} = $c->stash->{collection}->get_knowledge_base_by_entity_name(@entities_names);

    return $self->status_ok(
        $c,
        entity => {
            knowledge_base => [
                map {
                    my $k = $_;
                    +{
                        id                    => $k->id,
                        answer                => $k->answer,
                        saved_attachment_type => $k->saved_attachment_type,
                        saved_attachment_id   => $k->saved_attachment_id,
                        type                  => $k->type,
                        entities => [
                            map {
                                my $e = $_;

                                $recipient->add_to_politician_entity( $e->id );

                                +{
                                    id  => $e->id,
                                    tag => $e->name
                                }
                            } $k->entity_rs->all()
                        ]
                    }
                } $c->stash->{collection}->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
