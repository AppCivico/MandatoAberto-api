package MandatoAberto::Schema::ResultSet::PoliticianContact;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress URI PhoneNumber);

use Data::Verifier;

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
                twitter => {
                    required => 0,
                    type     => "Str",
                },
                facebook => {
                    required => 0,
                    type     => URI
                },
                email => {
                    required => 0,
                    type     => EmailAddress
                },
                cellphone => {
                    required => 0,
                    type     => "Str"
                },
                instagram => {
                    required => 0,
                    type     => URI
                },
                url => {
                    required => 0,
                    type     => URI
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

            my $contact;
            $self->result_source->schema->txn_do(sub {
                my $politician              = $self->result_source->schema->resultset('Politician')->find( $values{politician_id} );
                my $organization_chatbot_id = $politician->user->organization_chatbot_id;

				# Tratando contato como do organization_chatbot e não do politician
				delete $values{politician_id} and $values{organization_chatbot_id} = $organization_chatbot_id;

                my $existent_politician_contact = $self->search( { organization_chatbot_id => $organization_chatbot_id } )->next;

                if (!defined $existent_politician_contact) {
                    $contact = $self->create(\%values);
                } else {
                    $contact = $existent_politician_contact->update(\%values);
                }

                # $politician->logs->create(
                #     {
                #         timestamp => \'NOW()',
                #         action_id => 11
                #     }
                # );
            });

            return $contact;
        }
    };
}

1;