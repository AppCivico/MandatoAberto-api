package MandatoAberto::Schema::ResultSet::PoliticianBiography;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress URI PhoneNumber);

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
                        })->count and die \["politician_id", "politician alredy has a biography"];

                        return 1;
                    }
                },
                content => {
                    required => 1,
                    type     => "Str"
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

            if (length $values{content} > 640 ) {
                die \["content", "Mustn't be longer than 640 chars"];
            }

            my $politician_biography = $self->create(\%values);

            return $politician_biography;
        }
    };
}

1;