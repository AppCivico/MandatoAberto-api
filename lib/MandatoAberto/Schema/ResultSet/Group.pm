package MandatoAberto::Schema::ResultSet::Group;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use JSON::MaybeXS;
use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [ qw/ trim / ],
            profile => {
                name => {
                    required => 1,
                    type     => 'Str',
                },

                filter => {
                    required => 1,
                    type     => 'HashRef',
                    post_check => sub {
                        my $filter = $_[0]->get_value('filter');

                        # Caso não seja passado um filtro
                        # o grupo é criado como EMPTY
                        return 1 if !keys %{$filter};

                        my %allowed_operators = map { $_ => 1 } qw/ AND OR /;
                        my %allowed_data      = map { $_ => 1 } qw/ field value /;
                        my %allowed_rules     = map { $_ => 1 }
                            qw/
                            QUESTION_ANSWER_EQUALS QUESTION_ANSWER_NOT_EQUALS QUESTION_IS_NOT_ANSWERED
                            QUESTION_IS_ANSWERED GENDER_IS GENDER_IS_NOT INTENT_IS INTENT_IS_NOT
                            /
                        ;

                        return 0 unless $allowed_operators{$filter->{operator}};

                        my @rules = @{ $filter->{rules} || [] };
                        scalar @rules >= 1 or return 0;

                        for my $rule (@rules) {
                            $allowed_rules{$rule->{name}} or return 0;

                            if (defined($rule->{data})) {
                                ref $rule->{data} eq 'HASH' or return 0;

                                for my $k (keys %{ $rule->{data} }) {
                                    $allowed_data{$k} or return 0;
                                    ref($rule->{data}->{$k}) eq "" or return 0;
                                }
                            }
                        }

                        return 1;
                    },
                },

                politician_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset('Politician')->search( { 'me.user_id' => $politician_id } )->count;
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

            my $status;
            if (!keys %{$values{filter}}) {
                $values{filter} = {
                    operator => 'AND',
                    rules    => [
                        {
                            name => 'EMPTY'
                        }
                    ]
                }
            }

            return $self->create(
                {
                    name          => $values{name},
                    politician_id => $values{politician_id},
                    filter        => $values{filter},
                    status        => 'processing',
                }
            );
        },
    };
}

sub get_groups_ordered_by_recipient_count {
    my ($self) = @_;

    return $self->search(
        undef,
        {
            order_by => { '-desc' => 'recipients_count' },
            page     => 1,
            rows     => 3
        }
    );
}

sub extract_metrics {
    my ($self) = @_;

    return {
        count             => $self->count,
        suggested_actions => [
            {
                alert             => '',
                alert_is_positive => 0,
                link              => '',
                link_text         => ''
            },
        ],
		sub_metrics => [
			# Métrica: grupo com seguidores
            {
				text              => $self->search( { recipients_count => { '!=' => 0 } } )->count . ' grupos com seguidores',
				suggested_actions => []
			},
            # Métrica: grupo sem seguidores
            {
				text              => $self->search( { recipients_count => 0 } )->count . ' grupos sem seguidores',
				suggested_actions => []
			},
		]
    }
}

1;

