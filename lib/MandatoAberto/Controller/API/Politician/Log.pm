package MandatoAberto::Controller::API::Politician::Log;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
	my ($self, $c) = @_;

	$c->detach("/api/forbidden") unless $c->stash->{is_me};

	eval { $c->assert_user_roles(qw/politician/) };
	if ($@) {
		$c->forward("/api/forbidden");
	}
}

sub base : Chained('root') : PathPart('logs') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
	my ($self, $c) = @_;

	my $rs = $c->stash->{politician}->logs;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    my $cond;

    my $recipient_id = $c->req->params->{recipient_id};
    if ( $recipient_id ) {
        $cond = { 'me.recipient_id' => $recipient_id }
    }

    return $self->status_ok(
        $c,
        entity => {
            logs => [
                map {
                    my $l = $_;

                    +{
                        created_at  => $l->timestamp,
                        description => $l->description,
                        recipient   => {
                            id      => $l->recipient->id,
                            name    => $l->recipient->name,
                            picture => $l->recipient->picture
                        }
                    }
                } $rs->search(
                    $cond,
                    {
                        page     => $page,
                        rows     => $results,
                        order_by => { -desc => 'timestamp' }
                    }
                  )
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;