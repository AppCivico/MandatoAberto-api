package MandatoAberto::Controller::API::Poll::Question;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PollQuestion",
    no_user => 1,

    # AutoResultPUT.
    object_key     => "poll_questions",
    result_put_for => "update",

    # AutoResultGET
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/poll/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('question') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $question_id) = @_;
    use DDP;
    $c->stash->{collection} = $c->stash->{collection}->search( { id => $question_id } );

    my $question = $c->stash->{collection}->find($question_id);
    $c->detach("/error_404") unless ref $question;

    my $poll = $c->model("DB::Poll")->search( { id => $question->poll_id } )->next;
    $c->detach("/error_404") unless ref $poll;
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET { }

sub create : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub create_POST {
    my ($self, $c) = @_;

    my $question = $c->stash->{collection}->execute(
        $c,
        for  => "create",
        with => {
            %{ $c->req->params},
            poll_id => $c->stash->{poll}->id
        },
    );

    return $self->status_created(
        $c,
        location => $c->uri_for($self->action_for('result'), [ $question->id ]),
        entity   => { id => $question->id }
    );
}

__PACKAGE__->meta->make_immutable;

1;