package MandatoAberto::Controller::API::Politician::Issue;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoResultPUT";
with "CatalystX::Eta::Controller::AutoResultGET";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Issue",

    # AutoListGET
    list_key  => "issues",

    # AutoResultPUT.
    object_key                => "issue",
    result_put_for            => "update",
    prepare_params_for_update => sub {
        my ($self, $c, $params) = @_;

        my $ignore_flag = $c->req->params->{ignore} || 0;
        $params->{ignore} = $ignore_flag;

        $params->{open} = 0;

        if ($c->req->params->{groups}) {
            $c->req->params->{groups} =~ s/(\[|\]|(\s))//g;

            my @groups = split(',', $c->req->params->{groups});

            $params->{groups} = \@groups;
        } else {
            $params->{groups} = [];
        }

        return $params;
    },

    # AutoResultGET
    build_row => sub {
        return { $_[0]->get_columns() };
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->detach("/api/forbidden") unless $c->stash->{is_me};

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('issue') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $issue_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $issue_id } );

    my $issue = $c->stash->{collection}->find($issue_id);
    $c->detach("/error_404") unless ref $issue;

    $c->stash->{issue} = $issue;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    my $filter = $c->req->params->{filter};
	die \['filter', 'missing'] unless $filter;
	die \['filter', 'invalid'] unless $filter =~ m/^(open|closed|ignored)$/;

    my $cond;
    if ( $filter eq 'open' ) {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 1
        }
    }
    elsif ( $filter eq 'ignored' ) {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 0,
            reply              => \'IS NULL'
        }
    }
    else {
        $cond = {
            'me.politician_id' => $politician_id,,
            open               => 0,
            reply              => \'IS NOT NULL'
        }
    }

    # Desativando paginação por agora
    # my $page    = $c->req->params->{page}    || 1;
    # my $results = $c->req->params->{results} || 20;

    return $self->status_ok(
        $c,
        entity => {
            issues => [
                map {
                    my $i = $_;

					my $reply = $i->reply;
					my $open  = $i->open;

                    my ( $ignored_flag, $replied_flag );
                    if ( !$open && !$reply ) {
						$ignored_flag = 1;
						$replied_flag = 0;
                    }
                    elsif ( !$open && $reply ) {
                        $ignored_flag = 0;
                        $replied_flag = 1;
                    }
                    else {
                        $ignored_flag = 0;
                        $replied_flag = 0;
                    }

                    {
                        id           => $i->get_column('id'),
                        reply        => $i->get_column('reply'),
                        open         => $i->get_column('open'),
                        ignored      => $ignored_flag,
                        replied      => $replied_flag,
                        message      => $i->get_column('message'),
                        created_at   => $i->get_column('created_at'),
                        recipient    => {
                            id              => $i->get_column('recipient_id'),
                            name            => $i->recipient->get_column('name'),
                            profile_picture => $i->recipient->get_column('picture'),

                            groups => [
                                map {
                                    {
                                        id               => $_->id,
                                        name             => $_->get_column('name'),
                                        recipients_count => $_->get_column('recipients_count'),
                                        status           => $_->get_column('status'),
                                    }
                                } $i->recipient->groups_rs->all()
                            ]
                        }
                    }
                } $c->stash->{collection}->search(
                    $cond,
                    {
                        prefetch => 'recipient',
                        # page     => $page,
                        # rows     => $results,
                        order_by => 'recipient_id'
                    }
                  )->all()
            ]
        }
    );
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub result_GET {
    my ($self, $c) = @_;

    my $issue     = $c->stash->{issue};
    my $recipient = $c->stash->{issue}->recipient;

    my $reply = $issue->reply;
    my $open  = $issue->open;

    my ( $ignored_flag, $replied_flag );
    if ( !$open && !$reply ) {
        $ignored_flag = 1;
        $replied_flag = 0;
    }
    elsif ( !$open && $reply ) {
        $ignored_flag = 0;
        $replied_flag = 1;
    }
    else {
        $ignored_flag = 0;
        $replied_flag = 0;
    }

    return $self->status_ok(
        $c,
        entity => {
            id         => $issue->id,
            reply      => $issue->reply,
            open       => $issue->open,
            message    => $issue->message,
            created_at => $issue->created_at,
			ignored    => $ignored_flag,
            replied    => $replied_flag,
            recipient  => {
                id              => $recipient->id,
                name            => $recipient->name,
                profile_picture => $recipient->picture,

                groups => [
                    map {
                        {
                            id               => $_->id,
                            name             => $_->get_column('name'),
                            recipients_count => $_->get_column('recipients_count'),
                            status           => $_->get_column('status'),
                        }
                    } $recipient->groups_rs->all()
                ]
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;