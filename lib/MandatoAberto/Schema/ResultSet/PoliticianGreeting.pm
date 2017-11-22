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
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->search({
                            politician_id => $politician_id
                        })->count and die \["politician_id", "politician alredy has a greeting"];

                        return 1;
                    }
                },
                text => {
                    required   => 1,
                    type       => "Str",
                    max_length => 250,
                }
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

            if ( !$values{text} ) {
                die \[ "greeting", "Text mustn't be empty" ];
            }

            my $politician_greeting = $self->create( \%values );

            return $politician_greeting;
        },

    };
}

1;