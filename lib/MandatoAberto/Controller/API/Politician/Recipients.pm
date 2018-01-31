package MandatoAberto::Controller::API::Politician::Recipients;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with 'CatalystX::Eta::Controller::AutoListGET';

use Data::Printer;

__PACKAGE__->config(
     list_key       => 'recipients',
     build_list_row => sub {
        my ($r, $self, $c) = @_;

        return {
            id            => $r->get_column('id'),
            name          => $r->get_column('name'),
            cellphone     => $r->get_column('cellphone'),
            email         => $r->get_column('email'),
            gender        => $r->get_column('gender'),
            origin_dialog => $r->get_column('origin_dialog'),
            created_at    => $r->get_column('created_at'),

        };
     },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('recipients') : CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{collection} = $c->stash->{politician}->recipients;
}

#sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

__PACKAGE__->meta->make_immutable;

1;

