package MandatoAberto::Controller::API::Register::Poll;
use common::sense;
use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;

use MandatoAberto::Utils;
use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

__PACKAGE__->config(
    result  => "DB::Poll",
    no_user => 1,
);

with "CatalystX::Eta::Controller::AutoBase";

sub root : Chained('/api/register/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    $c->req->params->{poll_questions} = [];

    for my $param (keys %{ $c->req->params } ) {
        if ($param =~ m{^questions\[([0-9]+)\](\[([^\]]+)\])?(\[([0-9]+)\])?(\[([^\]]+)\])?$}) {
            $c->req->params->{poll_questions}->[$1] ||= {};

            if (!$3) {
                $c->req->params->{poll_questions}->[$1]->{content} = delete $c->req->params->{$param};
            }
            elsif ($3 eq 'options') {
                $c->req->params->{poll_questions}->[$1]->{poll_question_options}->[$5]->{content} = delete $c->req->params->{$param};
            }
        }
    }

    $c->req->params->{poll_questions} = [ grep defined, @{ $c->req->params->{poll_questions} } ];

    die \['questions[]', 'missing'] unless scalar(@{ $c->req->params->{poll_questions} }) >= 1;

    for (my $i = 0; $i < scalar @{ $c->req->params->{poll_questions} } ; $i++) {
        my $question = $c->req->params->{poll_questions}->[$i];

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

    my $poll = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{$c->req->params},
            politician_id => $c->user->id
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($c->controller("API::Poll")->action_for('result'), [ $poll->id ]),
        entity   => { id => $poll->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;