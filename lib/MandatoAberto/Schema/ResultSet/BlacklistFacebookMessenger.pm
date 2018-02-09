package MandatoAberto::Schema::ResultSet::BlacklistFacebookMessenger;
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
                recipient_id => {
                    required => 1,
                    type     => 'Int'
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

            my $existing_entry = $self->search( recipient_id => $values{recipient_id} )->next;

            if ($existing_entry) {
                return $existing_entry;
            } else {
                my $blacklist_entry = $self->create(\%values);

                return $blacklist_entry;
            }
        },
    };
}

1;