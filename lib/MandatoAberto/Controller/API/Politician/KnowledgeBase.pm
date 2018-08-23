package MandatoAberto::Controller::API::Politician::KnowledgeBase;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoListPOST';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultPUT';
with 'CatalystX::Eta::Controller::AutoResultGET';

__PACKAGE__->config(
    # AutoBase
    result  => 'DB::PoliticianKnowledgeBase',
    no_user => 1,

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->stash->{politician}->id;

        my $issue_id = $c->req->params->{issue_id};
        die \['issue_id', 'missing'] unless $issue_id;

        $params->{issues} = [$issue_id];

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
                    {
                        id  => $_->id,
                        tag => $_->name
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

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $filter = $c->req->params->{filter} || 'active';
    die \['filter', 'invalid'] unless $filter =~ /(active|inactive)/;

    my $cond;
    if ( $filter eq 'active' ) {
        $cond = {
            politician_id => $c->stash->{politician}->id,
            active        => 1
        };
    }
    elsif ( $filter eq 'inactive' ) {
		$cond = {
			politician_id => $c->stash->{politician}->id,
			active        => 0
		};
    }

    return $self->status_ok(
        $c,
        entity => {
            knowledge_base => [
                map {
                    my $kb = $_;

                    +{
                        id         => $kb->id,
                        answer     => $kb->answer,
                        created_at => $kb->created_at
                    }
                } $c->stash->{collection}->search( $cond )->all()
            ]
        }
    )
}


__PACKAGE__->meta->make_immutable;

1;