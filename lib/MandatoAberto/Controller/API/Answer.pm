package MandatoAberto::Controller::API::Answer;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
# with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Answer",

    # AutoResultPUT.
    object_key     => "answer",
    result_put_for => "update",

    # AutoListGET
    list_key => "answer",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('answer') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $answer_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $answer_id } );

    my $answer = $c->stash->{collection}->find($answer_id);
    $c->detach("/error_404") unless ref $answer;

    $c->stash->{is_me}  = int($c->user->id == $answer->politician_id);
    $c->stash->{answer} = $answer;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;

    return $self->status_ok(
        $c,
        entity => {
            answers => [
                map {
                    my $a = $_;
                    +{
                        question_id => $a->get_column('question_id'),
                        content     => $a->get_column('content'),
                    }
                } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
            ]
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result_PUT {
    my ($self, $c) = @_;

    $c->stash->{answer}->execute(
        $c,
        for  => "update",
        with => {
            %{ $c->req->params },
        },
    );

    return $self->status_accepted(
        $c,
        entity => { id => $c->stash->{answer}->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;