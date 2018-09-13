#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;

use Text::CSV;
use DDP;

my $schema = get_schema;

my $politician_kb_rs     = $schema->resultset('PoliticianKnowledgeBase');
my $politician_entity_rs = $schema->resultset('PoliticianEntity');
my $politician_rs        = $schema->resultset('Politician');

my $politician_id = 0;

# Setando politician_id correto para o usuário respectivo
$politician_id = 1;

my @rows;
my $csv = Text::CSV->new(
	{
		binary   => 1,
		eol      => $/,
        sep_char => ','
	}
) or die "Cannot use CSV: ".Text::CSV->error_diag();

open my $fh, '<:encoding(utf8)', '/tmp/kb.csv' or die "kb.csv: $!";

while ( my $row = $csv->getline($fh) ) {

    my $politician_entity = $politician_entity_rs->search(
        {
            name          => $row->[2],
            politician_id => $politician_id
        }
    )->next;
    die 'could not find entity for that politician with name: ' . $row->[2];

    my $kb = {
        politician_id => $politician_id,
        entities      => [ $politician_entity->id ],
        answer        => $row->[1],
    };

    push @rows, $kb;
}

$politician_kb_rs->populate(\@rows);
p $politician_kb_rs->count;

1;