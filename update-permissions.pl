#!/usr/bin/env perl
use common::sense;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use MandatoAberto::SchemaConnected;

my $schema = get_schema;

my $user_rs = $schema->resultset('User')->search( { id => { '!=' => 1 } } );

while ( my $user = $user_rs->next() ) {
    my $organization    = $user->organization;
    my $organization_id = $organization->id;

    if ( $organization->is_mandatoaberto ) {
        $organization->organization_modules->create_mandatoaberto_modules($organization_id);
        $user->add_all_permissions();
    }
    else {
        $organization->organization_modules->create_modules($organization_id);
		$user->add_basic_permissions();
    }
}

1;