package MandatoAberto::Utils;
use common::sense;

use Crypt::PRNG qw(random_string);
use Data::Section::Simple qw(get_data_section);

use vars qw(@ISA @EXPORT);

@ISA    = (qw(Exporter));
@EXPORT = qw(is_test get_data_section get_mandatoaberto_api_url_for);

sub is_test {
    if ($ENV{HARNESS_ACTIVE} || $0 =~ m{forkprove}) {
        return 1;
    }
    return 0;
}

sub get_mandatoaberto_api_url_for {
    my $args = shift;

    $args = "/$args" unless $args =~ m{^\/};
    my $mandatoaberto_url = $ENV{MANDATOABERTO_URL};
    $mandatoaberto_url =~ s/\/$//;

    return ( ( is_test() ? "http://localhost" : $mandatoaberto_url ) . $args );
}

1;