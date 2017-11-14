package MandatoAberto::Controller::API::Register::Poll;
use common::sense;
use Moose;
use namespace::autoclean;

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
    use DDP;
    for my $param (keys %{ $c->req->params } ) {
        if ($param =~ m{^question\[([0-9]+)\]\[([^\]]+)\](\[([0-9]+)\])?(\[([^\]]+)\])?$}) {
            $c->req->params->{poll_questions}->[$1] ||= {};
            $c->req->params->{poll_questions}->[$1]->{$2} = delete $c->req->params->{$param} unless $2 eq 'option';
            $c->req->params->{poll_questions}->[$1]->{question_options}->[$4]->{$6} = delete $c->req->params->{$param} unless $2 eq 'content';
        }
    }

    $c->req->params->{poll_questions}   = [ grep defined, @{ $c->req->params->{poll_questions} } ];
   
    die \['question[]', 'missing'] unless scalar(@{ $c->req->params->{poll_questions} }) >= 1;

    for (my $i = 0; $i < scalar @{ $c->req->params->{poll_questions} }; $i++) {
        my $questions = $c->req->params->{poll_questions}->[$i];

        for my $k (keys %{ $questions } ) {
            my $cons;
            if ($k eq 'content')    { $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint("Str") }

            die \["questions[$i][$k]", 'invalid'] if !ref($cons) || !$cons->check($questions->{$k});
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