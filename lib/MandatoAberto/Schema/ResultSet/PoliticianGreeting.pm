package MandatoAberto::Schema::ResultSet::PoliticianGreeting;
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
                    required   => 1,
                    type       => "Int",
                },
                on_facebook => {
                    required   => 1,
                    type       => 'Str',
                    max_lenght => 1000
                },
                on_website => {
                    required   => 1,
                    type       => 'Str',
                    max_lenght => 1000
                },
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

            my $greeting;
            $self->result_source->schema->txn_do(sub {
                my $politician              = $self->result_source->schema->resultset('Politician')->find( $values{politician_id} );
                my $organization_chatbot_id = $politician->user->organization_chatbot_id;

                # Tratando greetings como do organization_chatbot e não do politician
                delete $values{politician_id} and $values{organization_chatbot_id} = $organization_chatbot_id;

                my $existent_politician_greeting = $self->search( { organization_chatbot_id => $organization_chatbot_id } )->next;

                if (!defined $existent_politician_greeting) {
                    $greeting = $self->create(\%values);
                } else {
                    $greeting = $existent_politician_greeting->update(\%values);
                }

                # $politician->logs->create(
                #     {
                #         timestamp => \'NOW()',
                #         action_id => 10
                #     }
                # );

            });

            return $greeting;
        },
    };
}

1;
