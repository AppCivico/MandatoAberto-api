package MandatoAberto::Schema::ResultSet::MovementDiscount;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;


sub verifiers_specs {
	my $self = shift;

	return {
		create => Data::Verifier->new(
			filters => [qw(trim)],
			profile => {
				movement_id => {
					required   => 1,
					type       => "Int",
					post_check => sub {
						my $movement_id = $_[0]->get_value("movement_id");

						$self->result_source->schema->resultset('Movement')->search( { id => $movement_id } )->count;
					}
				},
				percentage => {
					required   => 0,
					type       => "Int",
					post_check => sub {
						my $movement_id = $_[0]->get_value("movement_id");

						$self->result_source->schema->resultset('Movement')->search( { id => $movement_id } )->count;
					}
				},
                movement_id => {
					required   => 0,
					type       => "Int",
					post_check => sub {
						my $movement_id = $_[0]->get_value("movement_id");

						$self->result_source->schema->resultset('Movement')->search( { id => $movement_id } )->count;
					}
				},
			}
		),
	};
}


sub action_specs {
	my ($self) = @_;

	return {
		create => sub {
			my $r = shift;

			my %values = $r->valid_values;
			not defined $values{$_} and delete $values{$_} for keys %values;

			my $movement = $self->create(\%values);

			return $movement;
		}
	};
}

1;