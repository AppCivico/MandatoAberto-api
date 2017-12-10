package MandatoAberto::Controller::API::Politician::Citizen;
use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);

BEGIN { extends "CatalystX::Eta::Controller::REST" }

with "CatalystX::Eta::Controller::AutoBase";
with "CatalystX::Eta::Controller::AutoListGET";

__PACKAGE__->config(
    result  => "DB::Citizen",
    no_user => 1,

    list_key => "citizens",
    build_row  => sub {
        return { $_[0]->get_columns() };
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('citizen') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

__PACKAGE__->meta->make_immutable;

1;