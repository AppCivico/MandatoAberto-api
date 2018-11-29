package MandatoAberto::Utils;
use common::sense;

use Crypt::PRNG qw(random_string);
use Data::Section::Simple qw(get_data_section);

use vars qw(@ISA @EXPORT);

@ISA    = (qw(Exporter));
@EXPORT = qw( is_test random_string get_data_section
    get_mandatoaberto_api_url_for get_mandatoaberto_httpcb_url_for
    get_metric_name_for_dashboard get_metric_text_for_dashboard
);

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

sub get_mandatoaberto_httpcb_url_for {
    my $args = shift;

    $args = "/$args" unless $args =~ m{^\/};
    my $mandatoaberto_httpcb_url = $ENV{MANDATOABERTO_HTTP_CB_URL};
    $mandatoaberto_httpcb_url =~ s/\/$//;

    return ( ( is_test() ? "http://localhost" : $mandatoaberto_httpcb_url ) . $args );
}

sub get_metric_name_for_dashboard {
    my ($relation) = @_;

    my $name;
    if ( $relation eq 'issues' ) {
        $name = 'issue';
    }
    elsif ( $relation eq 'campaigns' ) {
        $name = 'campaign';
    }
    elsif ( $relation eq 'groups' ) {
        $name = 'group';
    }
    elsif ( $relation eq 'polls' ) {
        $name = 'poll';
    }
    elsif ( $relation eq 'recipients' ) {
        $name = 'recipient';
    }
    elsif ( $relation eq 'politician_entities' ) {
        $name = 'entities';
    }
    else {
        die 'missing relation name on MandatoAberto::Utils on get_metric_name_for_dashboard'
    }

    return $name;
}

sub get_metric_text_for_dashboard {
    my ($relation) = @_;

    my $text;
    if ( $relation eq 'issues' ) {
        $text = 'Mensagens';
    }
    elsif ( $relation eq 'campaigns' ) {
        $text = 'Campanhas';
    }
    elsif ( $relation eq 'groups' ) {
        $text = 'Grupos';
    }
    elsif ( $relation eq 'polls' ) {
        $text = 'Consultas';
    }
    elsif ( $relation eq 'recipients' ) {
        $text = 'Seguidores';
    }
    elsif ( $relation eq 'politician_entities' ) {
        $text = 'Temas';
    }
    else {
        die 'missing relation name on MandatoAberto::Utils on get_metric_text_for_dashboard'
    }

    return $text;
}

1;
