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
                status_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $status_id = $_[0]->get_value("status_id");
                        $self->result_source->schema->resultset("PollStatus")->search( { id => $status_id } )->count == 1;
                    }
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
            if ($values{status_id} == 1) {
                my $active_poll = $self->result_source->schema->resultset("Poll")->search(
                    {
                        politician_id => $values{politician_id},
                        status_id     => 1
                    }
                );

                $active_poll->update( { status_id => 2 } ) if $active_poll;
            }

            # Não deve ser permitido criar uma enquete desativada
            # apenas inativa, pois uma vez desativada
            # uma enquete não pode ser ativada novamente
            die \['status_id', 'cannot created deactivated poll'] if $values{status_id} == 3;

            my $poll = $self->create(\%values);

            return $poll;
        }
    };
}

1;