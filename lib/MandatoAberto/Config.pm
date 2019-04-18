package MandatoAberto::Config;
use common::sense;

sub setup {
    my $app = shift;

    # Hypnotoad.
    my $api_port    = int($ENV{API_PORT});
    my $api_workers = int($ENV{API_WORKERS});

    $app->config->{hypnotoad} = {
        workers => $api_workers,
        listen  => ["http://*:${api_port}"],
        proxy   => 1,
        graceful_timeout => 600,
    };
}

1;
