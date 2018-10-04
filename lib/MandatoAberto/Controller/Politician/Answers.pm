package MandatoAberto::Controller::Politician::Answers;
use Mojo::Base 'MandatoAberto::Controller';

use Scalar::Util qw(looks_like_number);

sub get {
    my $c = shift;

    return $c->render(
        json => {
            answers => [
                map {
                    my $a = $_;

                   +{
                        id          => $a->get_column('id'),
                        content     => $a->get_column('content'),
                        question_id => $a->get_column('question_id'),
                        dialog_id   => $a->question->get_column('dialog_id')
                    }
                } $c->schema->resultset('Answer')->search(
                    { politician_id => $c->stash('politician')->get_column('user_id') },
                    { prefetch => [qw( question )] }
                )->all()
            ]
        }
    )
}

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $params->{answers} = [];
    my $i = 0;

    for my $param (keys %{ $params } ) {
        if ($param =~ m{^question\[([0-9]+)\](\[(answer)\])?(\[([0-9]+)\])?$}) {

            $params->{answers}->[$i] ||= {};

            if ($5 && looks_like_number($5)) {
                $params->{answers}->[$i] = {
                    id            => $5,
                    question_id   => $1,
                    content       => delete $params->{$param},
                    politician_id => $c->current_user->id,
                };
            } else {
                $params->{answers}->[$i] = {
                    question_id   => $1,
                    content       => delete $params->{$param},
                    politician_id => $c->current_user->id,
                };
            }
            $i++;
        }
    }

    $params->{answers} = [ grep { defined } @{ $params->{answers} } ];

    my $answers = $c->schema->resultset('Answer')->execute(
        $c,
        for  => "update_or_create",
        with => $params,
    );

    my $created_answers;
    if ($answers) {
        for (my $z = 0; $z < scalar @{ $answers } ; $z++) {
            my $created_answer = $answers->[$z];

            $created_answers->[$z] = {
                id      => $created_answer->get_column('id'),
                content => $created_answer->get_column('content')
            }
        }
    }

    return $c->render(
        status => 200,
        json   => { answers => \@$created_answers }
    );
}

1;
