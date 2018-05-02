package MandatoAberto::Schema::ResultSet::PoliticianVotolegalIntegration;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Types qw(EmailAddress);

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
                votolegal_id => {
                    required   => 1,
                    type       => "Int",
                },
                votolegal_email => {
                    required => 1,
                    type     => EmailAddress
                },
                username => {
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

            my $username         = delete $values{username};
            $values{website_url} = $ENV{VOTOLEGAL_FRONT_URL} . $username;

            my $existent_politician_votolegal_integration = $self->search(
                { politician_id => $values{politician_id} }
            )->next;

            if (!defined $existent_politician_votolegal_integration) {
                my $politician_votolegal_integration = $self->create(\%values);

                return $politician_votolegal_integration;
            } else {
                my $updated_politician_votolegal_integration = $existent_politician_votolegal_integration->update(\%values);

                return $updated_politician_votolegal_integration;
            }
        },
    };
}

1;
