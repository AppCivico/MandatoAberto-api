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

use JSON;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                politician_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $politician_id = $_[0]->get_value('politician_id');

                        $self->result_source->schema->resultset("Politician")->search({ user_id => $politician_id })->count;
                    }
                },
                chatbot_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $chatbot_id = $_[0]->get_value('chatbot_id');

                        $self->result_source->schema->resultset('OrganizationChatbot')->search({ id => $chatbot_id })->count;
                    }
                },
                name => {
                    required => 0,
                    type     => "Str"
                },
                fb_id => {
                    required => 1,
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
                        my $page_id  = $_[0]->get_value("page_id");

                        $self->result_source->schema->resultset("OrganizationChatbotFacebookConfig")->search({ page_id => $page_id })->count;
                    }
                },
                extra_fields => {
                    required => 0,
                    type     => 'Str'
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

            # Por agora os extra fields não existem como coluna na tabela de recipient
            my $extra_fields = delete $values{extra_fields};

            # Erros
            if ( !$values{politician_id} && !$values{chatbot_id} ) {
                die \['chatbot_id', 'missing'];
            }
            elsif ( $values{politician_id} && $values{chatbot_id} ) {
                die \['politician_id', 'invalid'];
            }

            my $recipient;
            $self->result_source->schema->txn_do( sub {

                # Upsert do recipient
                if ( $values{politician_id} ) {
                    my $politician              = $self->result_source->schema->resultset('Politician')->find($values{politician_id});
                    my $organization_chatbot_id = $politician->user->organization_chatbot_id;

                    delete $values{politician_id} and $values{organization_chatbot_id} = $organization_chatbot_id;
                }
                elsif ( $values{chatbot_id} ) {
                    $values{organization_chatbot_id} = delete $values{chatbot_id};
                }
                else {
                    die \['chatbot_id', 'missing'];
                }

                my $existing_citizen = $self->search( { 'me.fb_id' => $values{fb_id} } )->next;

                # Criando ou atualizando recipient
                if (!defined $existing_citizen) {

                    die \['name', 'missing'] unless $values{name};

                    $recipient = $self->create(\%values);
                } else {
                    $recipient = $existing_citizen->update(\%values);
                }

                # Tratando extra_fields
                if ( $extra_fields ) {
                    $extra_fields = eval { from_json( $extra_fields ) };
                    die \['extra_fields', 'invalid'] if $@;
                    die \['extra_fields', 'invalid'] unless ref $extra_fields eq 'HASH';

                    if ( $extra_fields->{custom_labels} ) {
                        die \['custom_labels', 'invalid'] unless ref $extra_fields->{custom_labels} eq 'ARRAY';

                        $self->upsert_labels(
                            labels                  => $extra_fields->{custom_labels},
                            recipient_id            => $recipient->id,
                            organization_chatbot_id => $recipient->organization_chatbot_id
                        )
                    }

                    if ( $extra_fields->{system_labels} ) {
                        die \['system_labels', 'invalid'] unless ref $extra_fields->{system_labels} eq 'ARRAY';

                        $self->upsert_labels(
                            labels                  => $extra_fields->{system_labels},
                            recipient_id            => $recipient->id,
                            organization_chatbot_id => $recipient->organization_chatbot_id
                        );
                    }
                }
            });

            return $recipient;
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
        elsif ($name eq 'GENDER_IS_NOT') {
            push @where_attrs, $self->_build_rule_gender_is_not($value);
        }
        elsif ($name eq 'EMPTY') {
            push @where_attrs, $self->_build_rule_empty();
        }
        elsif ($name eq 'INTENT_IS') {
            push @where_attrs, $self->_build_rule_intent_is($value);
        }
        elsif ($name eq 'INTENT_IS_NOT') {
            push @where_attrs, $self->_build_rule_intent_is_not($value);
        }
        elsif ($name eq 'LABEL_IS') {
            push @where_attrs, $self->_build_rule_label_is($value);
        }
        elsif ($name eq 'LABEL_IS_NOT') {
            push @where_attrs, $self->_build_rule_label_is_not($value);
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

sub _build_rule_gender_is_not {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
gender != ?
SQL_QUERY
}

sub _build_rule_intent_is {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
? = ANY (entities::int[])
SQL_QUERY
}

sub _build_rule_intent_is_not {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
NOT (? = ANY (entities::int[]))
SQL_QUERY
}

sub _build_rule_label_is {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
EXISTS(
    SELECT 1
    FROM recipient_label
    WHERE
        recipient_id = me.id AND
        label_id = ?
)
SQL_QUERY
}

sub _build_rule_label_is_not {
    my ($self, $value) = @_;

    return \[ <<'SQL_QUERY', $value ];
NOT EXISTS(
    SELECT 1
    FROM recipient_label
    WHERE
        recipient_id = me.id AND
        label_id = ?
)
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

sub extract_metrics {
    my ($self, %opts) = @_;

    $self = $self->search_rs( { 'me.created_at' => { '>=' => \"NOW() - interval '$opts{range} days'" } } ) if $opts{range};

    return {
        # Contagem total de seguidores
        count             => $self->count,
        description     => 'Aqui você vê as métricas sobre seus seguidores.',
        suggested_actions => [
            {
                alert             => '',
                alert_is_positive => 0,
                link              => '',
                link_text         => 'Ver seguidores'
            },
        ],
        sub_metrics => [
            # Métrica: Contagem total de seguidores.
            {
                text              => $self->count > 1 ? $self->count . ' já interagiram com seu assistente digital' : $self->count . ' já interagiu com seu assistente digital',
                suggested_actions => []
            },
        ]
    }
}

sub upsert_labels {
    my ($self, %opts) = @_;

    my @required_opts = qw( labels recipient_id organization_chatbot_id );
    defined $opts{$_} or die \["$_", 'missing'] for @required_opts;

    my $recipient_id = $opts{recipient_id};
    my $recipient    = $self->find($recipient_id);

    my (@labels, @label_names);
    for my $label ( @{$opts{labels}} ) {
        die \['custom_label', 'must have name'] unless $label->{name};

        # Tratando caso de remoção da label
        # deleto apenas a relação entre o recipient
        # e a label, e não a label em si.
        if ( $label->{deleted} && $label->{deleted} == 1 ) {
            $self->result_source->schema->resultset('RecipientLabel')->search(
                {
                    'me.recipient_id' => $recipient_id,
                    'label.name'      => $label->{name}
                },
                { prefetch => 'label' }
            )->delete;
            next;
        }

        # Colocando já no formato para o insert
        push @labels, "('$label->{name}', $opts{organization_chatbot_id})";
        push @label_names, $label->{name};
    }

    # Criando labels e recipient_labels e também grupos
    if ( scalar @labels > 0 ) {
        @labels = $self->result_source->schema->storage->dbh_do(
            sub {
                my ($storage, $dbh, @cols) = @_;

                my $values = join ',', @cols;
                $dbh->do("INSERT INTO label (name, organization_chatbot_id) VALUES $values ON CONFLICT DO NOTHING");
            },
            @labels
        );

        my @recipient_labels = $self->result_source->schema->resultset('Label')->search( { name => { -in => \@label_names } } )->get_column('id')->all();
        @recipient_labels = map { "($recipient_id, $_)" } @recipient_labels;
        @recipient_labels = $self->result_source->schema->storage->dbh_do(
            sub {
                my ($storage, $dbh, @cols) = @_;
                my $values = join ',', @cols;
                $dbh->do("INSERT INTO recipient_label (recipient_id, label_id) VALUES $values ON CONFLICT DO NOTHING");
            },
            @recipient_labels
        );

        # Adicionando recipient à grupos casos eles já existam
        $recipient->organization_chatbot->upsert_groups_for_labels;

        my $group_rs      = $recipient->organization_chatbot->groups;
        my $recipients_rs = $recipient->organization_chatbot->recipients;

        while (my $group = $group_rs->next()) {
            my $filter = $group->filter;

            my $should_add_to_this_group = $recipients_rs
            ->search_by_filter($filter)
            ->search(
                { 'me.id' => $recipient->id },
                { select => [ \'1' ] }
            )
            ->next;
            if ($should_add_to_this_group) {
                $recipient->add_to_group($group->id);
            }
        }
    }
}

1;

