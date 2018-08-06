package MandatoAberto::Controller::API::Politician::Entity;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoListGET';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoResultGET';

__PACKAGE__->config(
    # AutoBase
	result  => 'DB::PoliticianEntity',
	no_user => 1,

    # AutoListGET
	list_key => 'politician_entities',
    build_list_row => sub {
        my ($r, $self, $c) = @_;

        my $tag;
        my $entity_name = $r->entity->name;
        if ( $r->sub_entity_id ) {
            my $sub_entity_name = $r->sub_entity->name;
            $tag = "$entity_name: $sub_entity_name";
        }
        else {
            $tag = $entity_name;
        }

        return {
            id              => $r->id,
            recipient_count => $r->recipient_count,
            entity_id       => $r->entity_id,
            sub_entity_id   => $r->sub_entity_id,
            created_at      => $r->created_at,
            updated_at      => $r->updated_at,
            tag             => $tag,
        };
    },


    # AutoObject
    object_verify_type => 'int',
    object_key         => 'politician_entity',

    # AutoResultGET
    build_row => sub { return { $_[0]->get_columns() } },
);


sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
	my ($self, $c) = @_;

	$c->detach("/api/forbidden") unless $c->stash->{is_me};

	eval { $c->assert_user_roles(qw/politician/) };
	if ($@) {
		$c->forward("/api/forbidden");
	}
}

sub base : Chained('root') : PathPart('intent') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }


__PACKAGE__->meta->make_immutable;

1;