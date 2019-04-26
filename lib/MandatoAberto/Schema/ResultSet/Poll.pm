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
                name => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $name = $_[0]->get_value("name");

                        my $count = $self->search( { name => $name } )->count;

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

            my $poll = $self->create(\%values);

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
