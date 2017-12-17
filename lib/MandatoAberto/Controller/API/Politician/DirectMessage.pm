package MandatoAberto::Controller::API::Politician::DirectMessage;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoListPOST";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::DirectMessage",

    list_key  => "direct_messages",
    build_row => sub {
        return { $_[0]->get_columns() };
    },

    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        $params->{politician_id} = $c->user->id;

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) {
    my ($self, $c) = @_;

    eval { $c->assert_user_roles(qw/politician/) };
    if ($@) {
        $c->forward("/api/forbidden");
    }
}

sub base : Chained('root') : PathPart('direct-message') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

sub list_GET {
    my ($self, $c) = @_;

    my $politician_id = $c->stash->{politician}->id;

    return $self->status_ok(
        $c,
        entity => {
            direct_messages => [
                map {
                    my $dm = $_;

                    +{
                        id         => $dm->get_column('id'),
                        content    => $dm->get_column('content'),
                        sent       => $dm->get_column('sent'),
                        created_at => $dm->get_column('created_at')
                    }
                } $c->stash->{collection}->search( { politician_id => $politician_id } )->all()
            ]
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;