package MandatoAberto::Schema::ResultSet::Tag;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use JSON::MaybeXS;
use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [ qw/ trim / ],
            profile => {
                name => {
                    required => 1,
                    type     => 'Str',
                },

                filter => {
                    required => 1,
                    type     => 'HashRef',
                    post_check => sub {
                        my $filter = $_[0]->get_value('filter');

                        my %allowedOperators = map { $_ => 1 } qw/ AND OR /;
                        return 0 unless $allowedOperators{$filter->{operator}};

                        # TODO Validar os filtros.
                        return 1;
                    },
                },

                politician_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset('Politician')->search( { 'me.user_id' => $politician_id } )->count;
                    },
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

            return $self->create(
                {
                    name          => $values{name},
                    politician_id => $values{politician_id},
                    filter        => encode_json($values{filter}),
                }
            );
        },
    };
}

1;
