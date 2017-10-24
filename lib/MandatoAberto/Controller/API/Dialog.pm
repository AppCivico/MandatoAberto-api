package MandatoAberto::Controller::API::Dialog;
use Moose;
use namespace::autoclean;

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with 'CatalystX::Eta::Controller::Search';
with "CatalystX::Eta::Controller::AutoObject";
with "CatalystX::Eta::Controller::AutoResultGET";

__PACKAGE__->config(
    # AutoObject.
    object_key         => "dialog",
    object_verify_type => "int",

    # AutoResultGET
    build_row => sub {
        return { $_[0]->get_columns() };
    },

);

sub root : Chained('/api/logged') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('dialog') : CaptureArgs(0) { }

__PACKAGE__->meta->make_immutable;

1;