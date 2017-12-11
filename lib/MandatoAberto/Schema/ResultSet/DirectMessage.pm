package MandatoAberto::Schema::ResultSet::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use Data::Verifier;
use MandatoAberto::Utils;
use MandatoAberto::Messager::Template;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required => 1,
                    type     => "Int",
                },
                content => {
                    required   => 1,
                    type       => "Str",
                    max_length => 250,
                },
                name => {
                    required  => 1,
                    type      => "Str",
                    max_length => 50,
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

            my $direct_message = $self->create(\%values);

            # Depois de criada a messagem direta, devo adicionar uma entrada
            # na fila para cada citizen atrelado ao rep. público
            my @citizens = $self->result_source->schema->resultset("Citizen")->search(
                { politician_id => $values{politician_id} },
                { column        => [ qw(me.fb_id) ]  }
            )->all();

            foreach (@citizens) {
                my $citizen = $_;

                my $message = MandatoAberto::Messager::Template->new(
                    to      => $citizen->get_column('fb_id'),
                    message => $values{content}
                )->build_message;

                my $queued = $self->result_source->schema->resultset("DirectMessageQueue")->create( { direct_message_id => $direct_message->id } );

                return $queued;
            }

            return $direct_message;
        }
    };
}

1;
