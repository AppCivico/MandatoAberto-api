#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use Text::CSV;

use MandatoAberto::SchemaConnected;

my $schema = get_schema;

my $csv = Text::CSV->new( { binary => 1 } )
  or die "Failed to create a CSV handle: $!";
my $filename = "output.csv";
open my $fh, "<:encoding(utf8)", $filename or die "failed to create $filename: $!";

my $politician_rs        = $schema->resultset('Politician');
my $politician_entity_rs = $schema->resultset('PoliticianEntity');

while ( my $row = $csv->getline($fh) ) {
    while ( my $politician = $politician_rs->next() ) {
        my $entity = $politician_entity_rs->search(
            {
                politician_id => $politician->id,
                name          => $row->[0]
            }
        )->next;

        $entity->update( { human_name => $row->[1] } ) if $entity;
	}
}

1;