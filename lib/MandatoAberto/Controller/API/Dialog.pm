package MandatoAberto::Controller::API::Dialog;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";
with "CatalystX::Eta::Controller::AutoResultPUT";

__PACKAGE__->config(
    # AutoBase.
    result => "DB::Dialog",

    # AutoResultPUT.
    object_key     => "dialog",
    result_put_for => "update",

    # AutoListGET
    list_key => "dialog",
    build_row  => sub {
        return { $_[0]->get_columns() };
    }
);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) { }

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ($self, $c, $dialog_id) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search( { id => $dialog_id } );

    my $dialog = $c->stash->{collection}->find($dialog_id);
    $c->detach("/error_404") unless ref $dialog;

    $c->stash->{dialog} = $dialog;
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET {
    my ($self, $c) = @_;

    return $self->status_ok(
        $c,
        entity => {
            dialogs => [
                map {
                    my $d = $_;
                    +{
                        id      => $d->get_column('id'),
                        name    => $d->get_column('name'),

                        questions => +[
                            {
                                id      => $d->questions->get_column('id'),
                                name    => $d->questions->get_column('name'),
                                content => $d->questions->get_column('content')
                            }
                        ],
                    }
                } $c->stash->{collection}->search({}, { prefetch => [ qw/ questions / ] })->all()
            ],
        }
    );
}

sub result : Chained('object') : PathPart('') :Args(0) : ActionClass('REST') { }

sub result_PUT { }

__PACKAGE__->meta->make_immutable;

1;