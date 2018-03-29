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
                        })->count and die \["name", "alredy exists"];

                        return 1;
                    }
                },
                content => {
                    required   => 1,
                    type       => "Str",
                },
                citizen_input => {
                    required => 1,
                    type     => "Str"
                    # TODO validar citizen_input de acordo com o tamanho e se já existe um no banco
                },
                admin_id => {
                    required   => 1,
                    type       => "Int",
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

            $values{created_by_admin_id} = delete $values{admin_id};

            if (length $values{content} > 640 ) {
                die \["content", "Mustn't be longer than 640 chars"];
            }

            my $question = $self->create(\%values);

            return $question;
        }
    };
}

1;