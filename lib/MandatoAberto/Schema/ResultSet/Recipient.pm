package MandatoAberto::Schema::ResultSet::Recipient;
use common::sense;
use Moose;
use namespace::autoclean;

extends "DBIx::Class::ResultSet";

with "MandatoAberto::Role::Verification";
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Types qw(EmailAddress PhoneNumber);

use Data::Verifier;
use Data::Printer;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
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
                    required => 1,
                    type     => "Str"
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

                if ( ( !$values{origin_dialog} && $values{name} ) || ( !$values{origin_dialog} && !$values{name} ) ) {
                    die \["origin_dialog", "missing"];
                } elsif ( ( $values{origin_dialog} && !$values{name} ) ) {
                    die \["name", "missing"];
                }

                my $citizen = $self->create(\%values);

                return $citizen;
            } else {
                my $updated_citizen = $existing_citizen->update(\%values);

                return $updated_citizen;
            }
        }
    };
}

sub search_by_tag_id {
    my ($self, $tag_id) = @_;

    return $self->search( \[ 'EXIST(tags, ?)', $tag_id ] );
}

sub search_by_tag_filter {
    my ($self, $filter) = @_;

    my $operator = $filter->{operator} eq 'AND' ? '-and' : '-or';

    my @where_attrs = ();
    for my $rule (@{ $filter->{rules } }) {
        my $name = $rule->{name};

        if ($name eq 'QUESTION_ANSWER_EQUALS') {
            my $field = $rule->{data}->{field};
            my $value = $rule->{data}->{value};

            push @where_attrs, \[ <<'SQL_QUERY', $field, $value ],
EXISTS(
    SELECT 1
    FROM poll_result
    JOIN poll_question_option
      ON poll_result.poll_question_option_id = poll_question_option.id
    WHERE poll_result.citizen_id = me.id
      AND poll_question_option.poll_question_id = ?
      AND poll_question_option.content = ?
)
SQL_QUERY
        }
        else {
            die "rule name '$name' does not exists.";
        }
    }

    return $self->search( { $operator => \@where_attrs } );
}

1;

