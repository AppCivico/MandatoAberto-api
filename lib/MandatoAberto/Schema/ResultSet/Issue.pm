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

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                recipient_id => {
                    required => 1,
                    type     => "Int"
                },
                message => {
                    required   => 1,
                    type       => "Str",
                },
                entities => {
                    required   => 0,
                    type       => 'HashRef'
                }
            }
        ),
        batch_ignore => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                ids => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $ids = $_[0]->get_value('ids');

                        for my $id ( @{ $ids } ) {
                            my $issue = $self->search(
                                {
                                    id            => $id,
                                    politician_id => $_[0]->get_value('politician_id'),
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
                    required => 1,
                    type       => "Int",
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                ids => {
                    required   => 1,
                    type       => 'ArrayRef[Int]',
                    post_check => sub {
                        my $ids = $_[0]->get_value('ids');

                        for my $id ( @{$ids} ) {
                            my $issue = $self->search(
                                {
                                    id            => $id,
                                    politician_id => $_[0]->get_value('politician_id'),
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
            $self->result_source->schema->txn_do(sub {
                # Uma issue sempre é criada como aberta
                $values{open} = 1;

                my $politician = $self->result_source->schema->resultset('Politician')->find( $values{politician_id} );
                my $recipient  = $politician->recipients->find($values{recipient_id});
                my $entity_rs  = $self->result_source->schema->resultset('Entity');

                my @entities_id;
                if ( $values{entities} ) {
                    my $entity_val = $values{entities};

                    my $intent = $entity_val->{result}->{metadata}->{intentName};
                    die \['intentName', 'missing'] unless $intent;

                    $intent = lc $intent;
                    my $human_name = $politician->politician_entities->find_human_name($intent);
                    die \['entities', "could not find human_name for $intent"] unless $human_name;

                    my $upsert_entity = $politician->politician_entities->find_or_create(
                        {
                            name       => $intent,
                            human_name => $human_name
                        }
                    );

                    $recipient->add_to_politician_entity( $upsert_entity->id );
                    push @entities_id, $upsert_entity->id;
                }

                $issue = $self->create(
                    {
                        %values,
                        peding_entity_recognition => $values{entities} ? 0 : 1,
                        ( $values{entities} ? (entities => \@entities_id) : () )
                    }
                );
            });

            return $issue;
        },
        batch_ignore => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            $self->result_source->schema->txn_do(sub {
                for my $id ( @{ $values{ids} } ) {
                    my $issue = $self->find($id);

                    $issue->update( { open => 0 } );
                }
            });
        },
        batch_delete => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            $self->result_source->schema->txn_do(sub {
                for my $id ( @{ $values{ids} } ) {
                    my $issue = $self->find($id);

                    $issue->update( { deleted => 1 } );
                }
            });
        },
    };
}

sub get_politician_open_issues {
    my ($self) = @_;

    return $self->search( { open => 1 } );
}

sub get_open_issues_created_today {
    my ($self) = @_;

    return $self->search(
        {
            open       => 1,
            created_at => { '>=' => "yesterday()" }
        }
    );
}

sub extract_metrics {
    my ($self, $politician_id) = @_;

    my $issue_response_view = $self->result_source->schema->resultset('ViewAvgIssueResponseTime')->search( undef, { bind => [ $politician_id ] } )->next;
    use DDP; p $self->result_class;

    my $count_open        = $self->search( { open => 1 } )->count;
    my $count_ignored     = $self->search( { open => 0, reply => \'IS NULL' } )->count;
    my $count_replied     = $self->search( { open => 0, reply => \'IS NOT NULL' } )->count;
    my $avg_response_time = $issue_response_view ? $issue_response_view->avg_response_time : 0;

    return {
        count             => $self->count,
        suggested_actions => [
            {
                alert             => 'Tempo médio de respostas: ' . $avg_response_time,
                alert_is_positive => $avg_response_time <= 90 ? 1 : 0,
                link              => '',
                link_text         => ''
            }
        ],
        sub_metrics => [
            {
                text              => $count_open . ' mensagens em aberto',
                suggested_actions => []
            },
            {
                text              => $count_ignored . ' mensagens descartadas',
                suggested_actions => []
            },
            {
				text              => $count_replied . ' mensagens respondidas',
				suggested_actions => []
            }
        ]
    }
}

1;