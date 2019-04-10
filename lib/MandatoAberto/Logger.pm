package MandatoAberto::Logger;
use strict;
use DateTime;
use IO::Handle;
use Log::Log4perl qw(:easy);
use MandatoAberto::Utils qw/is_test/;

my $test_is_folder = $ARGV[-1] eq 't' || $ARGV[-1] eq 't/' || $ARGV[-1] eq './t' || $ARGV[-1] eq './t/';

if ( $ENV{MANDATOABERTO_API_LOG_DIR} ) {
    if ( -d $ENV{MANDATOABERTO_API_LOG_DIR} ) {
        my $date_now = DateTime->now->ymd('-');

        # vai ter q rever isso, quando é mojo..
        my $app_type = $0 =~ /\.psgi/ ? 'api' : &_extract_basename($0);

        my $log_file = $app_type eq 'api' ? "api.$date_now.$$" : "$app_type.$date_now";

        $ENV{MANDATOABERTO_API_LOG_FILE} = $ENV{MANDATOABERTO_API_LOG_DIR} . "/$log_file.log";
        print STDERR "Redirecting STDERR/STDOUT to $ENV{MANDATOABERTO_API_LOG_FILE}\n";
        close(STDERR);
        close(STDOUT);
        autoflush STDERR 1;
        autoflush STDOUT 1;
        open( STDERR, '>>', $ENV{MANDATOABERTO_API_LOG_FILE} ) or die 'cannot redirect STDERR';
        open( STDOUT, '>>', $ENV{MANDATOABERTO_API_LOG_FILE} ) or die 'cannot redirect STDOUT';

    }
    else {
        print STDERR "MANDATOABERTO_API_LOG_DIR is not a dir\n";
    }
}
else {
    print STDERR "MANDATOABERTO_API_LOG_DIR Not configured\n";
}

Log::Log4perl->easy_init(
    {
        level  => $DEBUG,
        layout => ( is_test() && $test_is_folder ? '' : '%p{1}%d{yyyy-MM-dd HH:mm:ss.SSS}[%P]%x %m{indent=1}%n' ),
        ( $ENV{MANDATOABERTO_API_LOG_FILE} ? ( file => '>>' . $ENV{MANDATOABERTO_API_LOG_FILE} ) : () ),
        'utf8'    => 1,
        autoflush => 1,

    }
);

# importa as funcoes para o script.
#no strict 'refs';
#*{"main::$_"} = *$_ for grep { defined &{$_} } keys %MANDATOABERTO::Logger::;
#use strict 'refs';

our @ISA = qw(Exporter);

our @EXPORT = qw(log_info log_fatal log_error get_logger);

my $logger = get_logger;

# logs
sub log_info {
    my (@texts) = @_;
    $logger->info( join ' ', @texts );
}

sub log_error {
    my (@texts) = @_;
    $logger->error( join ' ', @texts );
}

sub log_fatal {
    my (@texts) = @_;
    $logger->fatal( join ' ', @texts );
}

sub _extract_basename {
    my ($path) = @_;
    my ($part) = $path =~ /.+(?:\/(.+))$/;
    return lc($part);
}

1;
