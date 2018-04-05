package MandatoAberto::Schema::ResultSet::PoliticianChatbotConversation;
use common::sense;
use Moose;
use namespace::autoclean;

use YAML::XS;

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
                conversation_model => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $conversation_model = $_->get_value('dialog_model');
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

            my $existent_politician_chatbot_dialog = $self->search(
                { politician_id => $values{politician_id} }
            )->next;

            if (!defined $existent_politician_chatbot_dialog) {
                my $politician_chatbot_dialog = $self->create(\%values);

                return $politician_chatbot_dialog;
            } else {
                my $updated_politician_chatbot_dialog = $existent_politician_chatbot_dialog->update(\%values);

                return $updated_politician_chatbot_dialog;
            }
        }
    };
}

1;