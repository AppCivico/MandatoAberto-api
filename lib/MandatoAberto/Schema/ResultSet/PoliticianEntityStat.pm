package MandatoAberto::Schema::ResultSet::PoliticianEntityStat;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress PhoneNumber URI);

use Data::Verifier;
use Data::Printer;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_entity_id => {
                    required => 1,
                    type     => 'Int',
                },
                recipient_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
						my $recipient_id         = $_[0]->get_value('recipient_id');
                        my $politician_entity_id = $_[0]->get_value('politician_entity_id');

                        my $recipient_rs = $self->result_source->schema->resultset('Recipient');
                        my $recipient    = $recipient_rs->search( { id => $recipient_id } )->next or die \['recipient_id', 'invalid'];

                        my $politician_entity = $self->result_source->schema->resultset('PoliticianEntity')->find($politician_entity_id);

                        die \['recipient_id', 'invalid'] unless $politician_entity->politician->id == $recipient->politician_id;

                        return 1;
                    }
                },
                entity_is_correct => {
                    required => 1,
                    type     => 'Bool'
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

            my $stats;
            $self->result_source->schema->txn_do(sub {
                $stats = $self->create(\%values);

                $stats->recipient->add_to_politician_entity( $values{politician_entity_id} ) if $values{entity_is_correct} == 1;
            });

            return $stats;
        }
    };
}

1;

