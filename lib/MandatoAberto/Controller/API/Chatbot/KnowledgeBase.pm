package MandatoAberto::Controller::API::Chatbot::KnowledgeBase;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON;
use Encode;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianKnowledgeBase",
);

sub root : Chained('/api/chatbot/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('knowledge-base') : CaptureArgs(0) {  }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->req->params->{politician_id};
    die \["politician_id", "missing"] unless $politician_id;

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            'me.politician_id' => $politician_id,
            'me.active'        => 1
        }
    );

    my $entities = $c->req->params->{entities};
    die \['entities', 'missing'] unless $entities;
    $entities = decode_json(Encode::encode_utf8($entities)) or die \['entities', 'could not decode json'];

    my @required_json_fields = qw (intent parameters);
    die \['entities', "missing 'queryResult' param"] unless $entities->{queryResult};

    for (@required_json_fields) {
        die \['entities', "missing '$_' param"] unless $entities->{queryResult}->{$_};
    }

    # TODO melhorar esse bloco
    my @entities_names;
    push @entities_names, $entities->{queryResult}->{intent}->{displayName};

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