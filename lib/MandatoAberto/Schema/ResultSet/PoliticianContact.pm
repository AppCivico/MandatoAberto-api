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
                    type     => "Str"
                },
                instagram => {
                    required => 0,
                    type     => URI
                },
                url => {
                    required => 0,
                    type     => URI
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

            my $existent_politician_contact = $self->search(
                { politician_id => $values{politician_id} }
            )->next;

            if (!defined $existent_politician_contact) {
                my $politician_contact = $self->create(\%values);

                return $politician_contact;
            } else {
                my $updated_politician_contact = $existent_politician_contact->update(\%values);

                return $updated_politician_contact;
            }
        }
    };
}

1;