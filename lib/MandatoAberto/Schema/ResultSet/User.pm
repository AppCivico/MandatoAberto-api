package MandatoAberto::Schema::ResultSet::User;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress);

use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $email = $_[0]->get_value("email");
                        $self->result_source->schema->resultset("User")->search({ email => $email })->count == 0;
                    }
                },
                password => {
                    required => 1,
                    type     => "Str",
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

            if (length $values{password} < 6) {
                die \["password", "must have at least 6 characters"];
            }

            my $user = $self->create(\%values);
            $user->add_to_roles( { id => 2 } );

            return $user;
        }
    }
}

1;
