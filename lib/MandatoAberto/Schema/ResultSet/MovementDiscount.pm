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

                        my $movement_count = $self->result_source->schema->resultset('Movement')->search( { id => $movement_id } )->count;
                        die \['movement_id', 'could not find movement with that id'] unless $movement_count;

                        my $valid_movement_discount_count = $self->search(
                            {
                                movement_id => $movement_id,
                                valid_until => 'infinity'
                            }
                        )->count;
                        die \['movement_id', 'there alredy is a discount for that movement'] unless $valid_movement_discount_count == 0;

                        return 1;
                    }
                },
                percentage => {
                    required   => 0,
                    type       => "Num",
                    post_check => sub {
                        my $percentage = $_[0]->get_value("percentage");

                        die \['percentage', 'must be lesser or equal to 100.00%'] if $percentage > 100.00;
                        die \['percentage', 'must be greater than 0.00%'] if $percentage == 0.00;

                        return 1;
                    }
                },
                amount => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $amount = $_[0]->get_value("amount");

                        my $base_amount = $ENV{MANDATOABERTO_BASE_AMOUNT};
                        die \['$ENV{MANDATOABERTO_BASE_AMOUNT}', 'missing'] unless $base_amount;

                        die \['amount', 'must not be greater than base amount'] if $amount > $base_amount;

                        return 1;
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

            if ( $values{percentage} && $values{amount} ) {
                die \['amount', 'must have percentage or amount'];
            }
            elsif ( !$values{percentage} && !$values{amount} ) {
                die \['amount', 'must have percentage or amount'];
            }

            my $movement_discount = $self->create(\%values);

            return $movement_discount;
        }
    };
}

1;