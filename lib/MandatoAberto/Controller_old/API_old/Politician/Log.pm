package MandatoAberto::Controller::API::Politician::Log;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::TypesValidation";

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

    $self->validate_request_params(
        $c,
        recipient_id => {
            required   => 0,
            type       => 'Int'
        },
        date_range => {
            required => 0,
            type     => 'Int',
        },
        action_id => {
            required => 0,
            type     => 'Int'
        }
    );

    # Paginação
    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    # Tratando filtros por recipient, data e ação
    my %cond;

    my $recipient_id = $c->req->params->{recipient_id};
    if ( $recipient_id ) {
        $cond{'me.recipient_id'} = $recipient_id;
    }

    my $date_range = $c->req->params->{date_range};
    if ( $date_range ) {
        $cond{'me.timestamp'} = { '>=' => \"NOW() - interval '$date_range days'" };
    }

    my $action_id = $c->req->params->{action_id};
    if ( $action_id ) {
        $cond{'me.action_id'} = $action_id
    }

    my $rs = $c->stash->{politician}->logs->search(\%cond);

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
                    undef,
                    {
                        page     => $page,
                        rows     => $results,
                        order_by => { -desc => 'timestamp' }
                    }
                  )
            ],
            itens_count => $rs->count
        }
    )
}

sub admin : Chained('base') : PathPart('admin') : Args(0) : ActionClass('REST') { }

sub admin_GET {
    my ($self, $c) = @_;

    $self->validate_request_params(
        $c,
        date_range => {
            required => 0,
            type     => 'Int',
        },
        action_id => {
            required => 0,
            type     => 'Int'
        }
    );

    my $rs = $c->stash->{politician}->logs;

    # Paginação
    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    # Tratando filtros por recipient, data e ação
    my %cond;

    # Essa action retornará apenas logs de admin
    $cond{'action.is_recipient'} = 0;

    my $date_range = $c->req->params->{date_range};
    if ( $date_range ) {
        $cond{'me.timestamp'} = { '>=' => \"NOW() - interval '$date_range days'" };
    }

    my $action_id = $c->req->params->{action_id};
    if ( $action_id ) {
        $cond{'me.action_id'} = $action_id
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
                    }
                } $rs->search(
                    \%cond,
                    {
                        page     => $page,
                        rows     => $results,
                        order_by => { -desc => 'timestamp' },
                        prefetch => 'action'
                    }
                  )
            ]
        }
    )
}

__PACKAGE__->meta->make_immutable;

1;