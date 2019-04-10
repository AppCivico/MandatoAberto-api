package MandatoAberto::SchemaConnected;
use common::sense;
use FindBin qw($RealBin);
use Config::General;

BEGIN {
    for (qw(POSTGRESQL_HOST POSTGRESQL_PORT POSTGRESQL_DBNAME POSTGRESQL_USER POSTGRESQL_PASSWORD)) {
        defined($ENV{$_}) or die "missing env '$_'\n";
    }
};

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(get_schema get_connect_info);

use MandatoAberto::Schema;
use MandatoAberto::Utils;

sub get_connect_info {
    my $host     = $ENV{POSTGRESQL_HOST};
    my $port     = $ENV{POSTGRESQL_PORT} || 5432;
    my $user     = $ENV{POSTGRESQL_USER};
    my $password = $ENV{POSTGRESQL_PASSWORD};
    my $dbname   = $ENV{POSTGRESQL_DBNAME};

    return {
        dsn            => "dbi:Pg:dbname=$dbname;host=$host;port=$port",
        user           => $user,
        password       => $password,
        AutoCommit     => 1,
        quote_char     => "\"",
        name_sep       => ".",
        auto_savepoint => 1,
        pg_enable_utf8 => 1,
    };
}

sub get_schema {
	my $schema = MandatoAberto::Schema->connect( get_connect_info() );

	my $dbh = $schema->storage->dbh;
	my $confs =
	  $dbh->selectall_arrayref( 'select "name", "value" from config where valid_to = \'infinity\'', { Slice => {} } );

	foreach my $kv (@$confs) {
		my ( $k, $v ) = ( $kv->{name}, $kv->{value} );
		$ENV{$k} = $v;
	}

	print STDERR "Loaded " . scalar @$confs . " envs\n";
	return $schema;

}

1;