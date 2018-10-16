package MandatoAberto::Schema::ResultSet::Answer;
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
        update_or_create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                answers => {
                    required => 1,
                    type     => 'ArrayRef'
                }
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update_or_create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            my @answers;
            $self->result_source->schema->txn_do(sub {
                my $politician_id;
                my @logs;

                for (my $i = 0; $i < scalar @{ $values{answers} } ; $i++) {
                    my $answer = $values{answers}->[$i];

                    $politician_id = $answer->{politician_id} unless $politician_id;

                    if ($answer->{id}) {
                        my $answer_id      = $answer->{id};
                        my $located_answer = $self->find($answer_id);

                        next if $answer->{content} eq "";

                        die \["question[$i][answer][$answer_id]", 'could not find answer'] unless $located_answer;

                        my $updated_answer = $located_answer->update($answer);
                        push @answers, $updated_answer;

                        my $log = {
                            timestamp => \'NOW()',
                            action_id => 12,
                            field_id  => $answer_id
                        };
                        push @logs, $log;
                    } else {
                        $self->search(
                            {
                                politician_id => $answer->{politician_id},
                                question_id   => $answer->{question_id}
                            }
                        )->count and die \["question_id", "politician alredy has an answer for that question"];

                        my $new_answer = $self->create($answer);

                        push @answers, $new_answer;

						my $log = {
                            timestamp => \'NOW()',
							action_id => 12,
							field_id  => $new_answer->id
						};
						push @logs, $log;
                    }
                }

                my $politician = $self->result_source->schema->resultset('Politician')->find($politician_id);

                $politician->logs->populate(\@logs)
            });

            return \@answers;
        },
    };
}

sub get_answered_dialogs {
    my ($self) = @_;

    return available_dialogs => [
        map {
            my $a = $_;

            +{
                id   => $a->question->dialog->id,
                name => $a->question->dialog->name,
            }
        } $self->search(
            { },
            { prefetch => { 'question' => 'dialog' }  }
          )
    ]
}

1;