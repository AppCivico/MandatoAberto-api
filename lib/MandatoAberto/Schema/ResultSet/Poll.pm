package MandatoAberto::Schema::ResultSet::Poll;
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
                    required => 1,
                    type     => "Int"
                },
                name => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $name = $_[0]->get_value("name");
                        $self->result_source->schema->resultset("Poll")->search({ name => $name })->count == 0;
                    }
                },
                poll_questions => {
                    required => 1,
                    type     => "ArrayRef"
                },
                active => {
                    required   => 1,
                    type       => "Bool",
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

            # Caso tenha uma enquete ativa, essa deverá ser desativada
            # E a nova criada deverá ser já ativada
            if ($values{active} == 1) {
                my $active_poll = $self->result_source->schema->resultset("Poll")->search(
                    {
                        politician_id => $values{politician_id},
                        active        => 1
                    }
                );

                $active_poll->update( { active => 0 } );
            }

            my $poll = $self->create(\%values);

            return $poll;
        }
    };
}

1;