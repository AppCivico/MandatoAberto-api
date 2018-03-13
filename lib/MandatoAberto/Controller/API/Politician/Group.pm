package MandatoAberto::Controller::API::Politician::Group;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoListGET';
with 'CatalystX::Eta::Controller::AutoListPOST';
with 'CatalystX::Eta::Controller::AutoResultPUT';

__PACKAGE__->config(
    result      => 'DB::Group',

    object_verify_type => 'int',
    object_key         => 'group',

    list_key  => 'groups',
    build_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id               => $r->id,
            filter           => $r->filter,
            name             => $r->get_column('name'),
            status           => $r->get_column('status'),
            updated_at       => $r->get_column('updated_at'),
            created_at       => $r->get_column('created_at'),
            politician_id    => $r->get_column('politician_id'),
            recipients_count => $r->get_column('recipients_count'),
        };
    },

    data_from_body => 1,
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('group') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->model('DB::Group')->search(
        {
            'me.politician_id' => $c->user->id,
            'me.deleted'       => 'false',
        }
    );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET {
    my ($self, $c) = @_;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    my $group = $c->stash->{group};

    my $recipients_rs = $group->politician->recipients->search(
        {},
        {
            page => $page,
            rows => $results,
        },
    );

    return $self->status_ok(
        $c,
        entity => {
            id               => $group->id,
            filter           => $group->filter,
            name             => $group->get_column('name'),
            status           => $group->get_column('status'),
            updated_at       => $group->get_column('updated_at'),
            created_at       => $group->get_column('created_at'),
            politician_id    => $group->get_column('politician_id'),
            recipients_count => $group->get_column('recipients_count'),

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
        },
    );
}

sub result_PUT { }

sub result_DELETE {
    my ($self, $c) = @_;

    $c->stash->{group}->update(
        {
            deleted    => 'true',
            deleted_at => \'NOW()',
        }
    );

    return $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

around 'list_GET' => sub {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $page    = $c->req->params->{page}    || 1;
    my $results = $c->req->params->{results} || 20;

    $results = $results > 20 ? 20 : $results;

    $c->stash->{collection} = $c->stash->{collection}->search( {}, { page => $page, rows => $results } );

    $self->$orig(@_);
};

sub list_POST { }

sub count : Chained('base') : PathPart('count') : Args(0) : ActionClass('REST') { }

sub count_POST {
    my ($self, $c) = @_;

    my $filter = $c->req->data->{filter};

    return $self->status_ok(
        $c,
        entity => {
            count => $c->stash->{politician}->recipients->search_by_filter($filter)->count,
        },
    );
}

sub structure : Chained('base') : PathPart('structure') : Args(0) : ActionClass('REST') { }

sub structure_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            valid_operators => [ qw/ AND OR / ],

            valid_rules => [
                {
                    name      => 'QUESTION_ANSWER_EQUALS',
                    has_value => 1,
                },
                {
                    name      => 'QUESTION_ANSWER_NOT_EQUALS',
                    has_value => 1,
                },
                {
                    name      => 'QUESTION_IS_NOT_ANSWERED',
                    has_value => 0,
                },
                {
                    name      => 'QUESTION_IS_ANSWERED',
                    has_value => 0,
                },
            ],
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;

