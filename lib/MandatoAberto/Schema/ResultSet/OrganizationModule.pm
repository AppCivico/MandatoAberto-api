package MandatoAberto::Schema::ResultSet::OrganizationModule;
use common::sense;
use Moose;
use namespace::autoclean;
extends "DBIx::Class::ResultSet";

use DDP;

sub create_mandatoaberto_modules {
    my ($self, $organization_id) = @_;

    my @module_ids = $self->result_source->schema->resultset('Module')->get_column('id')->all();

    for my $id ( @module_ids ) {
        my $module = $self->find_or_create( { organization_id => $organization_id, module_id => $id } );
    }

    return 1;
}

sub create_modules {
	my ($self, $organization_id) = @_;

	my @module_ids = qw( 1 4 6 7 8 9 10 );

	for my $id (@module_ids) {
		my $module = $self->find_or_create( { organization_id => $organization_id, module_id => $id } );
	}

	return 1;
}

1;