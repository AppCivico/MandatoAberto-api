package MandatoAberto::Schema::ResultSet::Issue;
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
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({user_id => $politician_id})
                          ->count;
                    }
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required => 1,
                    type     => "Str",
                },
                entities => {
                    required => 0,
                    type     => 'HashRef'
                }
            }
        ),
        batch_ignore => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({user_id => $politician_id})
                          ->count;
                    }
                },
                ids => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $ids = $_[0]->get_value('ids');

                        my $politician_id = $_[0]->get_value('politician_id');
                        my $politician    = $self->result_source->schema->resultset('Politician')->find($politician_id);

                        for my $id (@{$ids}) {
                            my $issue = $self->search(
                                {
                                    id                      => $id,
                                    organization_chatbot_id => $politician->user->organization_chatbot_id,
                                }
                            )->next;

                            die \["issue_id: $id", 'no such issue'] unless $issue;
                        }

                        return 1;
                    }
                }
            }
        ),
        batch_delete => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({user_id => $politician_id})
                          ->count;
                    }
                },
                ids => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $ids = $_[0]->get_value('ids');

                        my $politician_id = $_[0]->get_value('politician_id');
                        my $politician    = $self->result_source->schema->resultset('Politician')->find($politician_id);

                        for my $id (@{$ids}) {
                            my $issue = $self->search(
                                {
                                    id                      => $id,
                                    organization_chatbot_id => $politician->user->organization_chatbot_id,
                                }
                            )->next;

                            die \["issue_id: $id", 'no such issue'] unless $issue;
                        }

                        return 1;
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

            my $issue;
            $self->result_source->schema->txn_do(
                sub {

                    my $politician
                      = $self->result_source->schema->resultset('Politician')->find($values{politician_id});
                    my $recipient = $politician->user->organization_chatbot->recipients->find($values{recipient_id});
                    my $entity_rs = $self->result_source->schema->resultset('Entity');
                    my $politician_entity = $self->result_source->schema->resultset('PoliticianEntity');

                    # Tratando issue como do organization_chatbot e não do politician
                    my $organization_chatbot_id = $politician->user->organization_chatbot->id;

                    delete $values{politician_id} and $values{organization_chatbot_id} = $organization_chatbot_id;

                    my @entities_id;
                    if ($values{entities}) {
                        my $entity_val = $values{entities};

                        my $intent = $entity_val->{queryResult}->{intent}->{displayName};
                        die \['intentName', 'missing'] unless $intent;

                        $intent = lc $intent;

                        if ($politician_entity->skip_intent($intent) == 0) {
                            my $human_name = $intent;
                            die \['entities', "could not find human_name for $intent"] unless $human_name;

                            my $upsert_entity
                              = $politician->user->organization_chatbot->politician_entities->find_or_create(
                                {
                                    name       => $intent,
                                    human_name => $human_name
                                }
                              );

                            $recipient->add_to_politician_entity($upsert_entity->id);
                            push @entities_id, $upsert_entity->id;

                        }

                    }

                    $issue = $self->create(
                        {
                            %values,
                            peding_entity_recognition => $values{entities} ? 0 : 1,
                            ($values{entities} ? (entities => \@entities_id) : ())
                        }
                    );

                    # Caso o chatbot tenha uma intent de fallback
                    # Já vinculo o usuário à intent.
                    if (
                        my $fallback_intent = $politician->user->organization_chatbot->politician_entities->search(
                            {'me.name' => 'default fallback intent'}
                        )->next
                      )
                    {
                        $recipient->add_to_politician_entity($fallback_intent->id);
                        $recipient->discard_changes;
                    }
                }
            );

            return $issue;
        },
        batch_delete => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            $self->result_source->schema->txn_do(
                sub {
                    for my $id (@{$values{ids}}) {
                        my $issue = $self->find($id);

                        $issue->update({deleted => 1});
                    }
                }
            );
        },
    };
}

sub get_politician_open_issues {
    my ($self) = @_;

    return $self->search({open => 1});
}

sub get_open_issues_created_today {
    my ($self) = @_;

    return $self->search(
        {
            open       => 1,
            created_at => {'>=' => "yesterday()"}
        }
    );
}

sub extract_metrics {
    my ($self, %opts) = @_;

    $self = $self->search_rs({'me.created_at' => {'>=' => \"NOW() - interval '$opts{range} days'"}}) if $opts{range};

    my $politician          = $self->result_source->schema->resultset('Politician')->find($opts{politician_id});
    my $issue_response_view = $self->result_source->schema->resultset('ViewAvgIssueResponseTime')
      ->search(undef, {bind => [$politician->user->organization_chatbot->id]})->next;

    my $count_open        = $self->search({reply => \'IS NULL', deleted => 0})->count;
    my $count_replied     = $self->search({reply => \'IS NOT NULL'})->count;
    my $avg_response_time = $issue_response_view ? $issue_response_view->avg_response_time : undef;

    # Caso nunca tenha respondido devo mostrar um texto específico
    my $text;
    if (!$avg_response_time) {
        $text = 'Você nunca respondeu suas mensagens!';
    }
    else {
        $text = 'Tempo médio de respostas: ' . $avg_response_time . ' minutos.';
    }

    my $alert_is_positive = $avg_response_time && $avg_response_time <= 90 ? 1          : 0;
    my $label             = $alert_is_positive                             ? 'positive' : 'negative';

    return {
        count       => $self->count,
        description =>
          'Aqui você poderá métricas sobre as mensagens que o assistente digital não conseguiu responder.',
        suggested_actions => [
            {
                alert             => $text,
                alert_is_positive => $alert_is_positive,
                label             => $label,
                link              => '',
                link_text         => 'Ver mensagens'
            }
        ],
        sub_metrics => [
            {
                text              => $count_open . ' mensagens em aberto',
                suggested_actions => []
            },
            {
                text              => $count_replied . ' mensagens respondidas',
                suggested_actions => []
            }
        ]
    };
}

1;
