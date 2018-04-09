package MandatoAberto::Schema::ResultSet::PoliticianChatbotConversation;
use common::sense;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS;

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
                    required => 1,
                    type     => 'ArrayRef',
                    post_check => sub {
                        my $conversation_model = $_[0]->get_value('conversation_model');

                        # Um modelo de conversação deve sempre
                        # ter o seu primeiro node tipo root
                        if ($conversation_model->[0]->{name} ne 'root') {
                            die \['conversation_model', 'First node must be root']
                        }
                        use DDP;
                        for (my $i = 0; $i < scalar @{ $conversation_model }; $i++) {
                            my $node      = $conversation_model->[$i];
                            my $node_name = $node->{name};
                            use DDP;
                            #p $node;

                            die \["$node_name", 'messages[] missing'] unless $node->{messages};
                            die \["$node_name", 'messages[] must be an array'] unless ref $node->{messages} eq 'ARRAY';

                        }
                        return 1;
                    },
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

            my $existent_politician_chatbot_dialog = $self->search(
                { politician_id => $values{politician_id} }
            )->next;

            if (!defined $existent_politician_chatbot_dialog) {

                my $politician_chatbot_dialog = $self->create(
                    {
                        conversation_model => encode_json($values{conversation_model}),
                        politician_id      => $values{politician_id}
                    }
                );
                return $politician_chatbot_dialog;
            } else {
                my $updated_politician_chatbot_dialog = $existent_politician_chatbot_dialog->update(
                    {
                        conversation_model => encode_json($values{conversation_model}),
                        politician_id      => $values{politician_id}
                    }
                );

                return $updated_politician_chatbot_dialog;
            }
        }
    };
}

1;