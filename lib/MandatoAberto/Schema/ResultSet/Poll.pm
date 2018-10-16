package MandatoAberto::Schema::ResultSet::Poll;
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
                    required => 1,
                    type     => "Int"
                },
                name => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $name          = $_[0]->get_value("name");
                        my $politician_id = $_[0]->get_value('politician_id');

                        my $count = $self->result_source->schema->resultset("Poll")->search(
                            {
                                name          => $name,
                                politician_id => $politician_id
                            }
                        )->count;
                        die \["name", 'alredy exists'] unless $count == 0;
                    }
                },
                poll_questions => {
                    required => 1,
                    type     => "ArrayRef"
                },
                status_id => {
                    required   => 1,
                    type       => "Int",
                    post_check => sub {
                        my $status_id = $_[0]->get_value("status_id");
                        $self->result_source->schema->resultset("PollStatus")->search( { id => $status_id } )->count == 1;
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

            my $poll;
            $self->result_source->txn_do(sub{

                # Caso tenha uma enquete ativa, essa deverá ser desativada
                # E a nova criada deverá ser já ativada
                if ($values{status_id} == 1) {
                    my $active_poll = $self->result_source->schema->resultset("Poll")->search(
                        {
                            politician_id => $values{politician_id},
                            status_id     => 1
                        }
                    );

                    $active_poll->update(
                        {
                            status_id  => 3,
                            updated_at => \'NOW()',
                        }
                    ) if $active_poll;
                }

                # Não deve ser permitido criar uma enquete desativada
                # apenas inativa, pois uma vez desativada
                # uma enquete não pode ser ativada novamente
                die \['status_id', 'cannot created deactivated poll'] if $values{status_id} == 3;

                $poll = $self->create(\%values);

                my $politician = $self->result_source->schema->resultset('Politician')->find($values{politician_id});

                if ( $politician->poll_self_propagation_active ) {
                    my $poll_self_propagation_rs = $self->result_source->schema->resultset('PollSelfPropagationQueue');
                    my @ids = $politician->recipients->search( { page_id => $politician->fb_page_id } )->only_opt_in->get_column('id')->all;

                    my @queue;
                    for my $id (@ids) {
                        my $queue = {
                            recipient_id => $id,
                            poll_id      => $poll->id
                        };

                        push @queue, $queue;
                    }

                    $poll_self_propagation_rs->populate(\@queue);
                }
            });

            return $poll;
        }
    };
}

sub get_active_politician_poll_with_data {
    my ($self) = @_;

    return $self->search(
        { status_id => 1 },
        { prefetch => [ 'poll_questions' , { 'poll_questions' => { "poll_question_options" => 'poll_results' } } ] }
    )->next;
}

sub get_non_propagated_polls {
    my ($self, $politician_id) = @_;

    die \['politician_id', 'missing'] unless $politician_id;

    return $self->search(
        {
            'me.id' => \"NOT IN ( SELECT poll_id FROM poll_propagate WHERE politician_id = $politician_id )"
        },
        { prefetch => 'poll_propagates' }
    );
}

sub non_self_propagated {
    my ($self) = @_;

    return $self->search(
        {
            'me.notification_sent'                => 0,
            'poll_self_propagation_config.active' => 1
        },
        {
            prefetch => [
                'politician',
                'poll_questions',
                { 'politician'     => 'poll_self_propagation_config' },
                { 'poll_questions' => "poll_question_options" }
            ]
        }
    );
}

1;