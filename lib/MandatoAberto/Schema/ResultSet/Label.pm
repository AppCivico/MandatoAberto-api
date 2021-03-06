package MandatoAberto::Schema::ResultSet::Label;
use common::sense;
use Moose;
use namespace::autoclean;

use DateTime::Format::DateParse;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use JSON;

sub resultset {
    my $self = shift;

    return $self->result_source->schema->resultset(@_);
}

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name => {
                    required => 1,
                    type     => 'Str'
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

            my $label;
            $self->result_source->schema->txn_do( sub {
                $label = $self->create(\%values);

                # Criando um grupo para a label.
                my $group = $label->organization_chatbot->groups->create(
                    {
                        name   => $label->name,
                        status => 'processing',
                        filter => to_json(
                            {
                                operator => 'AND',
                                rules => [
                                    {
                                        name => 'LABEL_IS',
                                        data => { value => $label->id },
                                    },
                                ],
                            }
                        ),
                    }
                ) unless $label->organization_chatbot->has_group_for_label($label->id);
            });

            return $label;
        }
    };
}

sub labels_GET {
    my ($self) = @_;

    return {
        labels => [
            map {
                +{
                    id         => $_->id,
                    name       => $_->name,
                    updated_at => $_->updated_at,
                    created_at => $_->created_at
                }
            } $self->all()
        ]
    }
}

1;
