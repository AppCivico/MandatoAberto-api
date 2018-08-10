package MandatoAberto::Controller::API::Politician::KnowledgeBase;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoListGET';
with 'CatalystX::Eta::Controller::AutoListPOST';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultPUT';
with 'CatalystX::Eta::Controller::AutoResultGET';

__PACKAGE__->config(
    # AutoBase
    result  => 'DB::PoliticianKnowledgeBase',
    no_user => 1,

    # AutoListGET
    list_key => 'knowledge_base',
    build_row  => sub {
        return { $_[0]->get_columns() };
    },

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->stash->{politician}->id;

        my $issue_id = $c->req->params->{issue_id};
        die \['issue_id', 'missing'] unless $issue_id;

        $params->{issues} = [$issue_id];

        # my $entities;
        # if ($c->req->params->{entities}) {
        #     $c->req->params->{entities} =~ s/(\[|\]|(\s))//g;

        #     my @entities = split(',', $c->req->params->{entities});

        #     $entities = \@entities;
        # } else {
        #     die \['entities', 'missing'];
        # }
        # $params->{entities} = $entities;

        return $params;
    },

    # AutoObject
    object_verify_type => 'int',
    object_key         => 'politician_knowledge_base',

    # AutoResultPUT.
    result_put_for => 'update',

    # AutoResultGET
    build_row => sub {
		my ($r, $self, $c) = @_;

        return {
            id         => $r->id,
            active     => $r->active,
            question   => $r->question,
            answer     => $r->answer,
            updated_at => $r->updated_at,
            created_at => $r->created_at,
            issues     => [
                map {
                    {
                        id => $_->id
                    }
                } $r->issue_rs->all()
            ],
            intents => [
                map {
					my $tag;
					my $entity_name = $_->entity->name;
					if ( $_->sub_entity_id ) {
						my $sub_entity_name = $_->sub_entity->name;
						$tag = "$entity_name: $sub_entity_name";
					}
                    else {
						$tag = $entity_name;
					}

                    {
                        id  => $_->id,
                        tag => $tag
                    }
                } $r->entity_rs->all()
            ]
        }
    },
);


sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('knowledge-base') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

sub result_PUT { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

sub list_POST { }


__PACKAGE__->meta->make_immutable;

1;