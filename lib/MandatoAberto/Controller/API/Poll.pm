package MandatoAberto::Controller::API::Poll;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Poll",


    # AutoListGET
    list_key => "poll",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_id } );

    my $poll = $c->stash->{collection}->find($poll_id);
    $c->detach("/error_404") unless ref $poll;

    $c->stash->{is_me}  = int($c->user->id == $poll->politician_id);
    $c->stash->{poll} = $poll;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    # my ($self, $c) = @_;

    # my $politician_id = $c->user->id;

    # return $self->status_ok(
    #     $c,
    #     entity => {
    #         answers => [
    #             map {
    #                 my $a = $_;
    #                 +{
    #                     question_id => $a->get_column('question_id'),
    #                     content     => $a->get_column('content'),
    #                 }
    #             } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
    #         ]
    #     }
    # );
}

__PACKAGE__->meta->make_immutable;

1;