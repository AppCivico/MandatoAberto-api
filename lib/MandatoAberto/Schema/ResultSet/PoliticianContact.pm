package MandatoAberto::Schema::ResultSet::PoliticianContact;
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
                    required => 1,
                    type     => "Int",
                },
                twitter => {
                    required => 0,
                    type     => "Str",
                },
                facebook => {
                    required => 0,
                    type     => URI
                },
                email => {
                    required => 0,
                    type     => EmailAddress
                },
                cellphone => {
                    required => 0,
                    type     => PhoneNumber
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

            if (!$values{twitter} && !$values{facebook} && !$values{email} && !$values{cellphone}) {
                die \["contact", "Must have at least one contact mean"];
            }

            my $politician_contact = $self->create(\%values);

            return $politician_contact;
        }
    };
}

1;