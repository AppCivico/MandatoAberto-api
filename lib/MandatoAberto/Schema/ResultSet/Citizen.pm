package MandatoAberto::Schema::ResultSet::Citizen;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress PhoneNumber);

use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                name => {
                    required => 1,
                    type     => "Str"
                },
                fb_id => {
                    required => 1,
                    type     => "Str"
                },
                origin_dialog => {
                    required => 1,
                    type     => "Str"
                },
                gender => {
                    required => 0,
                    type     => "Str"
                },
                email => {
                    required => 0,
                    type     => EmailAddress
                },
                cellphone => {
                    required => 0,
                    type     => PhoneNumber,
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

            if ($values{gender} && (length $values{gender} > 1 || !($values{gender} eq "F" || $values{gender} eq "M" )) ) {
                die \["gender", "must be F or M"];
            }

            my $citizen = $self->create(\%values);

            return $citizen;
        }
    };
}

1;