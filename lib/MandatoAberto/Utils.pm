package MandatoAberto::Utils;
use common::sense;

use Crypt::PRNG qw(random_string);
use Data::Section::Simple qw(get_data_section);

use vars qw(@ISA @EXPORT);

@ISA    = (qw(Exporter));
@EXPORT = qw( is_test random_string get_data_section
    get_mandatoaberto_api_url_for get_mandatoaberto_httpcb_url_for
    get_metric_name_for_dashboard get_metric_text_for_dashboard
	get_notification_name_for_bar get_notification_text_for_bar
    empty_metric
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
        $text = 'Pontos de vista';
    }
    else {
        die 'missing relation name on MandatoAberto::Utils on get_metric_text_for_dashboard'
    }

    return $text;
}

sub get_notification_name_for_bar {
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
        die 'missing relation name on MandatoAberto::Utils on get_notification_name_for_bar'
    }

    return $name;
}

sub get_notification_text_for_bar {
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
        $text = 'Pontos de vista';
    }
    else {
        die 'missing relation name on MandatoAberto::Utils on get_notification_text_for_bar'
    }

    return $text;
}

sub empty_metric {
    my ($metric) = @_;

    my $ret;
    if ( $metric eq 'issues' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui você poderá métricas sobre as mensagens que o assistente digital não conseguiu responder.',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    elsif ( $metric eq 'campaigns' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui ficam as métricas sobre as campanhas enviadas.',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    elsif ( $metric eq 'groups' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui você poderá ver as métricas sobre os grupos que você criou.',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    elsif ( $metric eq 'polls' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui será onde você poderá ver o desempenho de suas consultas',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    elsif ( $metric eq 'recipients' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui você vê as métricas sobre seus seguidores.',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    elsif ( $metric eq 'politician_entities' ) {
        $ret = {
            name              => get_metric_name_for_dashboard($metric),
            text              => get_metric_text_for_dashboard($metric),
            count             => 0,
            fallback_text     => 'Aqui você verá as métricas sobre seus temas.',
            suggested_actions => [],
            sub_metrics       => []
        };
    }
    else {
        die 'missing metric name on MandatoAberto::Utils on empty_metric'
    }
}

1;
