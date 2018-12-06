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
                recipient_fb_id => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $recipient_fb_id      = $_[0]->get_value('recipient_fb_id');
                        my $politician_entity_id = $_[0]->get_value('politician_entity_id');

                        my $recipient_rs = $self->result_source->schema->resultset('Recipient');
                        my $recipient    = $recipient_rs->search( { fb_id => $recipient_fb_id } )->next or die \['recipient_fb_id', 'invalid'];

                        my $politician_entity = $self->result_source->schema->resultset('PoliticianEntity')->find($politician_entity_id);

                        die \['recipient_fb_id', 'invalid'] unless $politician_entity->organization_chatbot_id == $recipient->organization_chatbot_id;

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
                my $recipient_rs = $self->result_source->schema->resultset('Recipient');

                my $recipient_fb_id = delete $values{recipient_fb_id};

                my $recipient = $recipient_rs->search( { fb_id => $recipient_fb_id } )->next;
                $values{recipient_id} = $recipient->id;

                $stats = $self->create(\%values);

                $stats->recipient->add_to_politician_entity( $values{politician_entity_id} ) if $values{entity_is_correct} == 1;
            });

            return $stats;
        }
    };
}

1;

