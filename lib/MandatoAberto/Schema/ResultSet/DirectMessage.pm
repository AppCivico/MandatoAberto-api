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

use Furl;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => {
                        my $politician_id = $_[0]->get_value('politician_id')
                    }
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

            my $furl = Furl->new();

            my $fb_access_token = $self->result_source->schema->resultset("Politician")->find($politician_id);

            # Depois de criada a messagem direta, devo adicionar uma entrada
            # na fila para cada citizen atrelado ao rep. público
            my @citizens = $self->result_source->schema->resultset("Recipient")->search(
                { politician_id => $values{politician_id} },
                { column        => [ qw(me.fb_id) ]  }
            )->all();

            foreach (@citizens) {
                my $citizen = $_;

                # Construo a request para o httpcallback
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
