package MandatoAberto::Schema::ResultSet::Question;
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
                dialog_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $dialog_id = $_[0]->get_value("dialog_id");
                        $self->result_source->schema->resultset("Dialog")->search({ id => $dialog_id })->count;
                    },
                },
                name => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $name = $_[0]->get_value("name");

                        $self->search({
                            name => $name,
                        })->count and die \["cpf", "alredy exists"];

                        return 1;
                    }
                },
                content => {
                    required   => 1,
                    type       => "Str",
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

            my $dialog = $self->create(
                { ( map { $_ => $values{$_} } qw(name dialog_id content) ) }
            );

            return $dialog;
        }
    };
}

1;