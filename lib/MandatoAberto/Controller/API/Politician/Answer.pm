package MandatoAberto::Controller::API::Politician::Answer;
use Moose;
use namespace::autoclean;

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

sub list_GET { }

sub list_POST {
    my ($self, $c) = @_;

    $c->req->params->{answers} = [];
    my $i = 0;

    for my $param (keys %{ $c->req->params } ) {
        if ($param =~ m{^question\[([0-9]+)\]$}) {
            
            $c->req->params->{answers}->[$i] ||= {};

            $c->req->params->{answers}->[$i] = {
                question_id   => $1,  
                content       => delete $c->req->params->{$param},
                politician_id => $c->user->id,
            };

            $i++;
        }
    }

    $c->req->params->{answers} = [ grep defined, @{ $c->req->params->{answers} } ];
    use DDP;
    for (my $i = 0; $i < scalar @{ $c->req->params->{answers} } ; $i++) {
        my $answer = $c->req->params->{answers}->[$i];
        p $answer;
        die \["answers[$i]", 'must not be empty'] if ( $answer->{content} eq "" );
    }

    my $answers = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => $c->req->params,
    );

    # TODO retornar array com ids
    return $self->status_ok(
        $c,
        entity => {}
    );
}

__PACKAGE__->meta->make_immutable;

1;