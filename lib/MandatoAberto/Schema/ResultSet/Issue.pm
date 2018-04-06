package MandatoAberto::Schema::ResultSet::Issue;
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

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required   => 1,
                    type       => "Str",
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

            # Uma issue sempre é criada como aberta
            $values{open} = 1;

            my $issue = $self->create(\%values);

            return $issue;
        }
    };
}

sub get_politician_open_issues_count {
    my ($self) = @_;

    return $self->search( { open => 1 } )->count;
}

sub get_recipient_open_issues {
    my ($self) = @_;

    return $self->search(
            { open => 1 },
            { order_by => 'created_at' }
        );
}

sub get_recipient_replied_issues {
    my ($self) = @_;

    return $self->search(
            {
                open  => 0,
                reply => \"IS NOT NULL"
            },
            { order_by => 'created_at' }
        );
}

sub get_recipient_ignored_issues {
    my ($self) = @_;

    return $self->search(
            {
                open  => 0,
                reply => \"IS NULL"
            },
            { order_by => 'created_at' }
        );
}

1;