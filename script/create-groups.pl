#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;

use JSON;

my $schema  = get_schema;
my $chatbot_rs = $schema->resultset('OrganizationChatbot');

while (my $chatbot = $chatbot_rs->next) {
    $chatbot->upsert_groups_for_labels;
}

1;