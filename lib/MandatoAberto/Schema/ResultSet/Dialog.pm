package MandatoAberto::Schema::ResultSet::Dialog;
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
                name => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $name = $_[0]->get_value("name");
                        $self->result_source->schema->resultset("Dialog")->search({ name => $name })->count == 0;
                    }
                },
                description => {
                    required => 1,
                    type     => "Str"
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

            my $dialog = $self->create(\%values);

            return $dialog;
        }
    };
}

sub get_dialogs_with_data {
    my ($self) = @_;

    return dialogs => [
        map {
            my $d = $_;

            {
                id          => $d->id,
                name        => $d->name,
                description => $d->description,
                created_at  => $d->created_at,
                created_by  => $d->created_by_admin->email,
                updated_at  => $d->updated_at,
                updated_by  => $d->updated_by_admin_id ? $d->updated_by_admin->email : undef,

                questions   => [
                    map {
                        my $q = $_;

                        {
                            id            => $q->id,
                            content       => $q->content,
                            citizen_input => $q->citizen_input,
                            created_at    => $q->created_at,
                            created_by    => $q->created_by_admin->email,
                            updated_at    => $q->updated_at,
                            updated_by    => $q->updated_by_admin_id ? $q->updated_by_admin->email : undef,
                        }
                    } $d->questions->all()
                ]
            }
        } $self->search(
            { },
            {
                prefetch => 'questions'
            }
          )->all()
    ]
}

1;