package MandatoAberto::Controller::API::Politician::Group;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::AutoListGET';
with 'CatalystX::Eta::Controller::AutoListPOST';

__PACKAGE__->config(
    result => 'DB::Group',

    object_verify_type => 'int',
    object_key         => 'group',

    list_key       => 'groups',
    build_list_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id            => $r->id,
            name          => $r->get_column('name'),
            politician_id => $r->get_column('politician_id'),
            filter        => $r->filter,
            updated_at    => $r->get_column('updated_at'),
            created_at    => $r->get_column('created_at'),
        };
    },

    data_from_body => 1,
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/politician/base') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('group') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { 'me.politician_id' => $c->user->id } );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;

