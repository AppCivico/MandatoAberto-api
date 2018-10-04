package MandatoAberto::Controller::Register::Poll;
use Mojo::Base 'MandatoAberto::Controller';

use MandatoAberto::Utils;
use Scalar::Util qw(looks_like_number);
use Moose::Util::TypeConstraints;

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $params->{poll_questions} = [];

    for my $param (keys %{ $params } ) {
        if ($param =~ m{^questions\[([0-9]+)\](\[([^\]]+)\])?(\[([0-9]+)\])?(\[([^\]]+)\])?$}) {
            $params->{poll_questions}->[$1] ||= {};

            if (!$3) {
                $params->{poll_questions}->[$1]->{content} = delete $params->{$param};
            }
            elsif ($3 eq 'options') {
                $params->{poll_questions}->[$1]->{poll_question_options}->[$5]->{content} = delete $params->{$param};
            }
        }
    }

    $params->{poll_questions} = [ grep { defined } @{ $params->{poll_questions} } ];

    die \['questions[]', 'missing'] unless scalar(@{ $params->{poll_questions} }) >= 1;

    for (my $i = 0; $i < scalar @{ $params->{poll_questions} } ; $i++) {
        my $question = $params->{poll_questions}->[$i];

        die \["questions[$i]", 'must have at least 2 options'] if ( !defined $question->{poll_question_options} || scalar(@{ $question->{poll_question_options} }) < 2 );

        for my $k ( keys %{ $question } ) {
            my $cons;

            if ($k eq 'content') {
                $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str');
                die \["question[$i]", 'invalid'] if !ref($cons) || !$cons->check($question->{$k}) || looks_like_number($question->{$k});
            }
            if ($k eq 'poll_question_options') {
                for (my $j = 0; $j < scalar @{ $question->{poll_question_options} }; $j++) {
                    my $question_option = $question->{poll_question_options}->[$j];

                    # Caso a enquete tenha 2 opções mas só tenha a opção 2 preenchida
                    # Isto é, apenas questions[$i][options][1] devo disparar um erro
                    die \["questions[$i][options][$j]", "missing"] if $j < 1 && ! defined $question_option;

                    # O Facebook tem um limite de 20 chars para botões de quick reply
                    if (length $question_option->{content} > 20) {
                        die \["questions[$i][options][$j]", "Options mustn't be longer than 20 characters"];
                    }
                }
            }
        }
    }

    my $poll = $c->schema->resultset('Poll')->execute(
        $c,
        for  => 'create',
        with => {
            %{ $params },
            politician_id => $c->current_user->id
        }
    );

    return $c
    ->redirect_to(undef) # TODO
    ->render(
        status => 201,
        json   => { id => $poll->id }
    );

}

1;
