package MandatoAberto::Schema::ResultSet::OrganizationModule;
use common::sense;
use Moose;
use namespace::autoclean;
extends "DBIx::Class::ResultSet";

sub create_mandatoaberto_modules {
    my ($self) = @_;

    my @module_ids = $self->result_source->schema->resultset('Module')->get_column('id')->all();
    my @organization_modules;
    for my $id ( @module_ids ) {
        my $module = { module_id => $id };

        push @organization_modules, $module;
    }

    return $self->populate(\@organization_modules);
}

sub create_modules {
	my ($self) = @_;

	my @module_ids = qw( 1 4 6 7 8 9 10 );

	my @organization_modules;
	for my $id (@module_ids) {
		my $module = { module_id => $id };

		push @organization_modules, $module;
	}

	return $self->populate(\@organization_modules);
}

1;