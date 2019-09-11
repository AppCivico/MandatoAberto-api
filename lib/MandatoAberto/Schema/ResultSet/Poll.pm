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
                        my $politician    = $self->result_source->schema->resultset('Politician')->find($politician_id);

                        my $count = $self->result_source->schema->resultset("Poll")->search(
                            {
                                name                    => $name,
                                organization_chatbot_id => $politician->user->organization_chatbot_id
                            }
                        )->count;

                        die \["name", 'alredy exists'] unless $count == 0;
                    }
                },
                poll_questions => {
                    required => 1,
                    type     => "ArrayRef"
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

            my $politician_id = delete $values{politician_id};
            my $politician    = $self->result_source->schema->resultset('Politician')->find($politician_id);

            $values{organization_chatbot_id} = $politician->user->organization_chatbot_id;

            my $poll;
            $self->result_source->schema->txn_do(sub{

                $poll = $self->create(\%values);

                if ( $politician->poll_self_propagation_active ) {
                    my $poll_self_propagation_rs = $self->result_source->schema->resultset('PollSelfPropagationQueue');
                    my @ids = $politician->user->organization_chatbot->recipients->search( { page_id => $politician->fb_page_id } )->only_opt_in->get_column('id')->all;

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
        undef,
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

sub extract_metrics {
    my ($self) = @_;

    return {
        count             => $self->count,
        description     => 'Aqui será onde você poderá ver o desempenho de suas consultas',
        suggested_actions => [
            {
                alert             => 'Melhore o seu engajamento',
                alert_is_positive => 0,
                link              => '',
                link_text         => ''
            },
        ],
        sub_metrics => [ ]
    }
}

1;
