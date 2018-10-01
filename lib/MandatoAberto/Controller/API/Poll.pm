package MandatoAberto::Controller::API::Poll;
use Moose;
use namespace::autoclean;

use DateTime;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Poll",

    # AutoResultPUT.
    object_key     => "poll",
    result_put_for => "update",

    # AutoListGET
    list_key => "poll",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $poll_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $poll_id } );

    my $poll = $c->stash->{collection}->find($poll_id);
    $c->detach("/error_404") unless ref $poll;

    $c->stash->{is_me} = int($c->user->id == $poll->politician_id);
    $c->stash->{poll}  = $poll;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;

    return $self->status_ok(
        $c,
        entity => {
            polls => [
                map {
                    my $p = $_;

                    +{
                        id          => $p->get_column('id'),
                        name        => $p->get_column('name'),
                        status_id   => $p->get_column('status_id'),

                        ( $p->status_id == 1 ? ( active_time => $p->created_at->subtract_datetime( DateTime->now() ) ) : ( ) ),

                        questions => [
                            map {
                                my $pq = $_;
                                +{
                                    id      => $pq->get_column('id'),
                                    content => $pq->get_column('content'),

                                    options => [
                                        map {
                                            my $qo = $_;

                                            +{
                                                id      => $qo->get_column('id'),
                                                content => $qo->get_column('content'),
                                                count   => $qo->poll_results->search()->count,
                                            }
                                        } $pq->poll_question_options->all()
                                    ]
                                }

                            } $p->poll_questions->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { 'me.politician_id' => $politician_id },
                    { prefetch => [ 'poll_questions' , { 'poll_questions' => { "poll_question_options" => 'poll_results' } } ] }
                )->all()
            ],
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;