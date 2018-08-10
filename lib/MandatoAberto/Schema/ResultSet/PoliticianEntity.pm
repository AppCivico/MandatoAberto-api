package MandatoAberto::Schema::ResultSet::PoliticianEntity;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

sub upsert {
    my ($self, $entity) = @_;

	my $upsert_entity = $self->find_or_create(
		{
			sub_entity_id => undef,
			entity        => { name => 'foo' },
		},
	);

    return $upsert_entity;
}

sub find_or_create_entities {
    my ($self, @entities) = @_;

    my $entity_rs = $self->result_source->schema->resultset('Entity');
    my $politician_entity;
    for my $entity (@entities) {

        my $global_entity = $entity_rs->search( { name => $entity } )->next;

        if ( $global_entity ) {
			$politician_entity = $self->search(
				{
					sub_entity_id => \'IS NULL',
					'entity.name' => $entity
				},
				{ prefetch => 'entity' }
			)->next;

            if ( !$politician_entity ) {
                $politician_entity = $self->create( { entity_id => $global_entity->id } );
            }
        }
        else {
			$global_entity     = $entity_rs->create( { name => $entity } );
            $politician_entity = $self->create( { entity_id => $global_entity->id } );
        }

    }

    return $self->count;
}

sub find_or_create_sub_entities {
	my ($self, @sub_entities) = @_;

	my $sub_entity_rs = $self->result_source->schema->resultset('SubEntity');
	my $politician_entity;
	for my $sub_entity (@sub_entities) {

		my $global_entity = $sub_entity_rs->search( { name => $sub_entity } )->next;

		if ($global_entity) {
			$politician_entity = $self->search(
				{ 'sub_entity.name' => $sub_entity },
				{ prefetch => 'sub_entity' }
			)->next;

			if ( !$politician_entity ) {
				$politician_entity = $self->create( { sub_entity_id => $global_entity->id } );
			}
		}
        else {
			$global_entity     = $sub_entity_rs->create( { name => $sub_entity } );
			$politician_entity = $self->create( { sub_entity_id => $global_entity->id } );
		}

	}

	return $self->count;
}

1;
