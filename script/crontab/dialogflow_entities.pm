#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;

my $dialogflow_ws = WebService::Dialogflow->instance;

my $schema = get_schema;

my $entity_rs    = $schema->resultset('Entity');
my $politician_rs = $schema->resultset('Politician');

$entity_rs->sync_with_dialogflow();

while ( my $politician = $politician_rs->next() ) {
    $politician->politician_entities->
}

1;