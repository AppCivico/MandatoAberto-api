package MandatoAberto::Controller::API::Register;
use common::sense;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

sub root :Chained('/api/root') :PathPart('') :CaptureArgs(0) { }

sub base :Chained('root') :PathPart('register') :CaptureArgs(0) { }

__PACKAGE__->meta->make_immutable;

1;