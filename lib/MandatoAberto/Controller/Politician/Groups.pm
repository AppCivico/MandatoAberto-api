package MandatoAberto::Controller::Politician::Groups;
use Mojo::Base 'MandatoAberto::Controller';

sub stasher {
    my $c = shift;

    my $group_id = $c->param('group_id');

    my $group = $c->schema->resultset('Group')->search( { 'me.id' => $group_id, 'me.deleted' => 'false' } )->next;

    if (!ref $group) {
        $c->reply_not_found;
        $c->detach();
    }

    $c->stash(group => $group);

    if ($group->politician_id != $c->current_user->id) {
        $c->reply_forbidden();
        $c->detach;
    }
    return $c;
}

sub post {
    my $c = shift;

    my $params = $c->req->json;
    $params->{politician_id} = $c->current_user->id;

    my $group = $c->schema->resultset('Group')->execute(
        $c,
        for  => 'create',
        with => $params,
    );

    $c->render(
        status => 201,
        json   => { id => $group->id }
    );
}

sub get {
    my $c = shift;

    my $page    = $c->req->params->to_hash->{page}    || 1;
    my $results = $c->req->params->to_hash->{results} || 20;
    $results    = $results <= 20 ? $results : 20;

    $c->stash->{collection} = $c->schema->resultset('Group')->search( { politician_id => $c->stash->{politician}->id }, { page => $page, rows => $results } );

    my $total = $c->stash->{collection}->count;

    my @rows;
    while ( my $r = $c->stash->{collection}->next() ) {
        push @rows, {
            id               => $r->id,
            filter           => $r->filter,
            name             => $r->get_column('name'),
            status           => $r->get_column('status'),
            updated_at       => $r->get_column('updated_at'),
            created_at       => $r->get_column('created_at'),
            politician_id    => $r->get_column('politician_id'),
            recipients_count => $r->get_column('recipients_count'),
        };
    }

    return $c->render(
        status => 200,
        json  => {
            total  => $total,
            groups => \@rows,
        }
    );
}

sub put {
    my $c = shift;

    $c->stash->{group}->execute(
        $c,
        for  => 'update',
        with => $c->req->json
    );

    return $c->render(
        status => 202,
        json   => {
            id => $c->stash->{group}->id
        }
    );
}

sub get_result {
	my $c = shift;

    my $group         = $c->stash->{group};
	my $recipients_rs = $group->politician->recipients;

	return $c->render(
		status => 200,
		json   => {
			id               => $group->id,
            filter           => $group->filter,
            name             => $group->name,
            status           => $group->status,
            updated_at       => $group->updated_at,
            created_at       => $group->created_at,
            politician_id    => $group->politician_id,
            recipients_count => $group->recipients_count,

            recipients => [
                map {
                    my $r = $_;
                    +{
                        id         => $r->id,
                        name       => $r->get_column('name'),
                        email      => $r->get_column('email'),
                        gender     => $r->get_column('gender'),
                        picture    => $r->get_column('picture'),
                        cellphone  => $r->get_column('cellphone'),
                        created_at => $r->get_column('created_at'),
                    }
                } $recipients_rs->search_by_group_ids($group->id)->all()
            ]
		}
	);
}

sub delete {
    my $c = shift;

	$c->stash->{group}->update(
		{
			deleted    => 'true',
			deleted_at => \'NOW()',
		}
	);

    return $c->render(
        status => 204,
        json   => {}
    );
}

1;

__END__


