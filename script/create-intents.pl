#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;
use WebService::Dialogflow;

my $df = WebService::Dialogflow->instance;

my $schema         = get_schema;
my $entity_rs      = $schema->resultset('PoliticianEntity')->search( undef, {group_by => 'me.name'} );
my @entitites_name = $entity_rs->get_column('name')->all();

for my $intent (@entitites_name) {
    my %intent = ( displayName => $intent );

    $df->create_intent(%intent);
}

1;