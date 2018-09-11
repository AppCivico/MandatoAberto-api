#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;

my $schema = get_schema;

my $politician_entity_rs = $schema->resultset('PoliticianEntity');

$politician_entity_rs->sync_dialogflow();

1;