package MandatoAberto::Controller::API::Politician::Answer;
use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    result  => "DB::Answer",
    no_user => 1,

    list_key => "answer",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },
);


sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('answers') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            answers => [
                map {
                    my $a = $_;

                   +{
                        id          => $a->get_column('id'),
                        content     => $a->get_column('content'),
                        question_id => $a->get_column('question_id'),
                        dialog_id   => $a->question->get_column('dialog_id')
                    }
                } $c->stash->{collection}->search(
                    { politician_id => $c->stash->{politician}->user_id },
                    { prefetch => [ qw / question / ] }
                )->all()
            ]
        }
    )
}

sub list_POST {
    my ($self, $c) = @_;

    $c->req->params->{answers} = [];
    my $i = 0;

    for my $param (keys %{ $c->req->params } ) {
        if ($param =~ m{^question\[([0-9]+)\](\[(answer)\])?(\[([0-9]+)\])?$}) {

            $c->req->params->{answers}->[$i] ||= {};

            if ($5 && looks_like_number($5)) {
                $c->req->params->{answers}->[$i] = {
                    id            => $5,
                    question_id   => $1,
                    content       => delete $c->req->params->{$param},
                    politician_id => $c->user->id,
                };
            } else {
                $c->req->params->{answers}->[$i] = {
                    question_id   => $1,
                    content       => delete $c->req->params->{$param},
                    politician_id => $c->user->id,
                };
            }

            $i++;
        }
    }

    $c->req->params->{answers} = [ grep defined, @{ $c->req->params->{answers} } ];

    my $answers = $c->stash->{collection}->execute(
        $c,
        for  => "update_or_create",
        with => $c->req->params,
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

    return $self->status_ok(
        $c,
        entity => {
            answers => \@$created_answers
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;