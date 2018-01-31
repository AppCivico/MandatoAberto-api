package MandatoAberto::Schema::ResultSet::Issue;
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
                politician_id => {
                    required   => 1,
                    type       => "Int"
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required   => 1,
                    type       => "Str",
                    max_length => 250
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

            # Uma issue sempre é criada como aberta
            $values{status} = 'open';

            my $issue = $self->create(\%values);

            return $issue;
        }
    };
}

1;