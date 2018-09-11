package MandatoAberto::Schema::ResultSet::Recipient;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress PhoneNumber URI);

use Data::Verifier;
use Data::Printer;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                platform => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $platform = $_[0]->get_value('platform');

                        die \['platform', 'invalid'] unless $platform =~ m/^(twitter|facebook)$/;
                    }
                },
                politician_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                name => {
                    required => 0,
                    type     => "Str"
                },
                fb_id => {
                    required => 0,
                    type     => "Str"
                },
                twitter_id => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $twitter_id        = $_[0]->get_value('twitter_id');
                        my $twitter_origin_id = $_[0]->get_value('twitter_origin_id');

                        die \['twitter_origin_id', 'missing'] unless $twitter_origin_id;

                        return 1;
                    }
                },
                twitter_origin_id => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $twitter_id = $_[0]->get_value('twitter_id');

                        die \['twitter_id', 'missing'] unless $twitter_id;
                    }
                },
                twitter_screen_name => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $twitter_id = $_[0]->get_value('twitter_id');

                        die \['twitter_id', 'missing'] unless $twitter_id;
                    }
                },
                origin_dialog => {
                    required => 0,
                    type     => "Str"
                },
                gender => {
                    required => 0,
                    type     => "Str"
                },
                email => {
                    required => 0,
                    type     => EmailAddress
                },
                cellphone => {
                    required => 0,
                    type     => PhoneNumber,
                },
                picture => {
                    required => 0,
                    type     => URI
                },
                session => {
                    required => 0,
                    type     => 'Str'
                },
                page_id => {
                    required   => 1,
                    type       => "Str",
                    post_check => sub {
                        my $page_id = $_[0]->get_value("page_id");
                        my $platform  = $_[0]->get_value('platform');

                        if ( $platform eq 'facebook' ) {
                            $self->result_source->schema->resultset("Politician")->search({ fb_page_id => $page_id })->count;
                        }
                        else {
                            $self->result_source->schema->resultset("Politician")->search({ twitter_id => $page_id })->count;
                        }

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

            if ( defined($values{gender}) && $values{gender} !~ m{^[FM]{1}$} ) {
                die \["gender", "must be F or M"];
            }

            my $existing_citizen = $self->search( { 'me.fb_id' => $values{fb_id} } )->next;

            if (!defined $existing_citizen) {

                die \['name', 'missing'] unless $values{name};

                my $citizen = $self->create(\%values);

                return $citizen;
            } else {
                if ( $values{poll_notification_sent} && $values{poll_notification_sent} == 1 ) {
                    my $poll = $existing_citizen->politician->get_activated_poll;
                    die \['politician_id', 'no active poll'] unless $poll;

                    $existing_citizen->poll_notification->update_or_create(
                        {
                            sent    => 1,
                            poll_id => $poll->id
                        }
                    );
                }

                my $updated_citizen = $existing_citizen->update(\%values);

                return $updated_citizen;
            }
        }
    };
}

sub only_opt_in {
    my ($self) = @_;

    return $self->search( { 'me.fb_opt_in' => 'true' } );
}

sub search_by_group_ids {
    my ($self, @group_ids) = @_;

    return $self->search(
        {
            '-and' => [
                '-or' => [
                    map { \[ 'EXIST(groups, ?)', $_ ] } @group_ids
                ],
            ],
        },
    );
}

sub search_by_filter {
    my ($self, $filter) = @_;

    ref($filter)          eq 'HASH'  or die 'invalid filter';
    ref($filter->{rules}) eq 'ARRAY' or die 'invalid rules';
    defined($filter->{operator})     or die 'invalid operator';

    my $operator = $filter->{operator} eq 'AND' ? '-and' : '-or';

    my @where_attrs = ();
    for my $rule (@{ $filter->{rules } }) {
        my $name  = $rule->{name};
        my $field = $rule->{data}->{field};
        my $value = $rule->{data}->{value};

        if ($name eq 'QUESTION_ANSWER_EQUALS') {
            push @where_attrs, $self->_build_rule_question_answer_equals($field, $value);
        }
        elsif ($name eq 'QUESTION_ANSWER_NOT_EQUALS') {
            push @where_attrs, $self->_build_rule_question_answer_not_equals($field, $value);
        }
        elsif ($name eq 'QUESTION_IS_ANSWERED') {
            push @where_attrs, $self->_build_rule_question_is_answered($field);
        }
        elsif ($name eq 'QUESTION_IS_NOT_ANSWERED') {
            push @where_attrs, $self->_build_rule_question_not_answered($field);
        }
        elsif ($name eq 'GENDER_IS') {
            push @where_attrs, $self->_build_rule_gender_is($value);
        }
        elsif ($name eq 'EMPTY') {
            push @where_attrs, $self->_build_rule_empty();
        }
        else {
            die "rule name '$name' does not exists.";
        }
    }

    # TODO Validar esse hack que evita que, em filtros sem regras, o resultset busque todos os recipients da base, pois
    # não haverá nenhuma condição em @where_attrs.
    #return $self->search(
    #    {
    #        '-or' => [
    #            { $operator => \@where_attrs },
    #            \[ "TRUE = FALSE" ],
    #        ],
    #    },
    #);

    return $self->search( { $operator => \@where_attrs } );
}

sub _build_rule_question_is_answered {
    my ($self, $field) = @_;

    return \[ <<'SQL_QUERY', $field ];
EXISTS(
    SELECT 1
    FROM poll_result
    JOIN poll_question_option
      ON poll_result.poll_question_option_id = poll_question_option.id
    WHERE poll_result.recipient_id = me.id
      AND poll_question_option.poll_question_id = ?
)
SQL_QUERY
}

sub _build_rule_question_not_answered {
    my ($self, $field) = @_;

    return \[ <<'SQL_QUERY', $field ];
NOT EXISTS(
    SELECT 1
    FROM poll_result
    JOIN poll_question_option
      ON poll_result.poll_question_option_id = poll_question_option.id
    WHERE poll_result.recipient_id = me.id
      AND poll_question_option.poll_question_id = ?
)
SQL_QUERY
}

sub _build_rule_question_answer_equals {
    my ($self, $field, $value) = @_;

    return \[ <<'SQL_QUERY', $field, $value ];
EXISTS(
    SELECT 1
    FROM poll_result
    JOIN poll_question_option
      ON poll_result.poll_question_option_id = poll_question_option.id
    WHERE poll_result.recipient_id = me.id
      AND poll_question_option.poll_question_id = ?
      AND poll_question_option.content = ?
)
SQL_QUERY
}

sub _build_rule_question_answer_not_equals {
    my ($self, $field, $value) = @_;

    return \[ <<'SQL_QUERY', $field, $value ];
EXISTS(
    SELECT 1
    FROM poll_result
    JOIN poll_question_option
      ON poll_result.poll_question_option_id = poll_question_option.id
    WHERE poll_result.recipient_id = me.id
      AND poll_question_option.poll_question_id = ?
      AND poll_question_option.poll_question_id IS NOT NULL
      AND poll_question_option.content <> ?
)
SQL_QUERY
}

sub _build_rule_empty {
    my ($self) = @_;

    return \[ <<'SQL_QUERY' ];
EXISTS(
    SELECT 1
    FROM recipient
    WHERE true = false
)
SQL_QUERY
}

sub _build_rule_gender_is {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
gender = ?
SQL_QUERY
}

sub get_recipient_by_gender {
    my ($self) = @_;

    my $male_recipients   = $self->search( { gender => "M" } )->count;
    my $female_recipients = $self->search( { gender => "F" } )->count;

    return {
        male_recipient_count   => $male_recipients,
        female_recipient_count => $female_recipients
    };
}

sub get_recipients_poll_results {
    my ($self) = @_;

    return $self->search(
        undef,
        { prefetch => 'poll_results' }
    );
}

1;

