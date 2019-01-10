package MandatoAberto::Schema::ResultSet::OrganizationChatbotStatus;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS;

use WebService::Facebook;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                organization_chatbot_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $organization_chatbot_id = $_[0]->get_value('organization_chatbot_id');

                        $self->result_source->schema->resultset('OrganizationChatbot')->search( { id => $organization_chatbot_id } )->count;
                    }
                },
                err_msg => {
                    required => 0,
                    type     => 'HashRef'
                },
                access_token_valid => {
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

            # Caso o access_token esteja válido, não deve ser enviado o param err_msg.
            if ( $values{access_token_valid} == 1 && defined $values{err_msg} ) {
                die \['err_msg', 'invalid'];
            }

			my $status = $self->find_or_create(
                { organization_chatbot_id => $values{organization_chatbot_id} },
                { key => 'organization_chatbot_status_organization_chatbot_id_key' }
            );

            $status->update(
                {
                    access_token_valid => $values{access_token_valid},
                    ( $values{err_msg} ? ( err_msg => encode_json $values{err_msg} ) : ( ) )
                }
            );

            return $status;
        }
    };
}

1;