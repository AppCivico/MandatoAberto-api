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
                        # e não deve ter parent
                        die \["conversation_model", "First node must be root"] unless $conversation_model->[0]->{name} eq 'root';
                        die \["conversation_model", "First node must not have parent"] if $conversation_model->[0]->{parent};

                        use DDP;
                        for (my $i = 0; $i < scalar @{ $conversation_model }; $i++) {
                            my $node      = $conversation_model->[$i];
                            my $node_name = $node->{name};
                            my $node_type = $node->{type};

                            die \['name', "missing on conversation_model[$i]"] if !$node_name;
                            die \['type', "missing on $node_name"] if !$node_type;
                            die \['messages[]', "missing on $node_name"] unless $node->{messages};
                            die \['messages[]', "must be an array on $node_name"] unless ref $node->{messages} eq 'ARRAY';

                            die \["$node_name", 'options[] missing'] if $node_type eq 'quick_reply' && !$node->{options};

                            if ($node_type eq 'prompt') {
                                die \["$node_name", 'prompt type missing'] if !$node->{prompt}->{type};
                                die \["$node_name", 'prompt name missing'] if !$node->{prompt}->{name};

                                my $node_prompt = $node->{prompt};

                                if ($node_prompt->{type} eq 'extra_field') {
                                    die \['$node_name', 'prompt field missing'] unless $node_prompt->{field};
                                }
                            } else {
                                die \["$node_name", 'options object missing']
                            }
                            die \["$node_name", 'prompt object missing'] if $node_type eq 'prompt' && !$node->{prompt};
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