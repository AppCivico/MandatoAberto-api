package MandatoAberto::Controller::API::Politician::Biography;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListPOST";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianBiography",

    # AutoResultPUT.
    object_key     => "politician_biography",
    result_put_for => "update",

    list_key  => "politician_biography",
    build_row => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('biography') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $biography_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $biography_id } );

    my $biography = $c->stash->{collection}->find($biography_id);
    $c->detach("/error_404") unless ref $biography;

    $c->stash->{biography} = $biography;

    $c->stash->{is_me} = int($c->user->id == $biography->politician_id);
    $c->detach("/api/forbidden") unless $c->stash->{is_me};
}

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_PUT { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->user->id;

    return $self->status_ok(
        $c,
        entity => {
            politician_id => $politician_id,

            map {
                my $b = $_;
                id      => $b->get_column('id'),
                content => $b->get_column('content')
            } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;