package MandatoAberto::Controller::API::Question;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Question",

    # AutoResultPUT.
    object_key     => "question",
    result_put_for => "update",

    # AutoListGET
    list_key => "question",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('question') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $question_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $question_id } );

    my $question = $c->stash->{collection}->find($question_id);
    $c->detach("/error_404") unless ref $question;

    $c->stash->{question} = $question;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;
    use DDP; p $c->stash;
    # return $self->status_ok(
    #     $c,
    #     entity => {

    #     }
    # );
}

sub result : Chained('object') : PathPart('') :Args(0) : ActionClass('REST') { }

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;