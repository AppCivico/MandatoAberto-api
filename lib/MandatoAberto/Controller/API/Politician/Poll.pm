package MandatoAberto::Controller::API::Politician::Poll;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Poll",

    # AutoListGET
    list_key => "poll",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('poll') : CaptureArgs(0) { }

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

    return $self->status_ok(
        $c,
        entity => {
            polls => [
                map {
                    my $p = $_;
                    +{
                        id        => $p->get_column('id'),
                        name      => $p->get_column('name'),
                        status_id => $p->get_column('status_id'),

                        questions => [
                            map {
                                my $pq = $_;
                                +{
                                    id      => $pq->get_column('id'),
                                    content => $pq->get_column('content'),
                                }

                            } $p->poll_questions->all()
                        ]
                    }
                } $c->stash->{collection}->search(
                    { 'me.politician_id' => $c->stash->{politician}->id },
                    { prefetch => 'poll_questions' }
                )->all()
            ]
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

__PACKAGE__->meta->make_immutable;

1;