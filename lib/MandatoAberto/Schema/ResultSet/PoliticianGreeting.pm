package MandatoAberto::Schema::ResultSet::PoliticianGreeting;
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
                    type       => "Int",
                },
                on_facebook => {
                    required   => 1,
                    type       => 'Str',
                    max_lenght => 300
                },
                on_website => {
                    required   => 1,
                    type       => 'Str',
                    max_lenght => 300
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

            my $existent_politician_greeting = $self->search(
                { politician_id => $values{politician_id} }
            )->next;

            if (!defined $existent_politician_greeting) {
                my $politician_greeting = $self->create(\%values);

                return $politician_greeting;
            } else {
                my $updated_politician_greeting = $existent_politician_greeting->update(\%values);

                return $updated_politician_greeting;
            }
        },
    };
}

1;
