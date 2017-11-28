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

            for (my $i = 0; $i < scalar @{ $values{answers} } ; $i++) {
                my $answer = $values{answers}->[$i];

                if ($answer->{id}) {
                    my $answer_id = $answer->{id};
                    my $located_answer = $self->find($answer_id);

                    die \["question[$i][answer][$answer_id]", 'could not find answer'] unless $located_answer;

                    my $updated_answer = $located_answer->update($answer);
                    push @answers, $updated_answer;
                } else {
                    $self->search(
                        {
                            politician_id => $answer->{politician_id},
                            question_id   => $answer->{question_id}
                        }
                    )->count and die \["question_id", "politician alredy has an answer for that question"];

                    my $new_answer = $self->create($answer);

                    push @answers, $new_answer;
                }
            }
            use DDP;
            # p \@answers;

            return \@answers;
        },
    };
}

1;