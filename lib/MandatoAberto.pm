package MandatoAberto;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Authentication
    Authorization::Roles
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name     => 'MandatoAberto',
    encoding => "UTF-8",


    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 0,
);

after setup_finalize => sub {
    my $app = shift;

    for my $key (keys %ENV) {
        $app->log->info($key . ' = ' . $ENV{$key});
    }
};

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

MandatoAberto - Catalyst based application

=head1 SYNOPSIS

    script/mandatoaberto_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MandatoAberto::Controller::Root>, L<Catalyst>

=head1 AUTHOR

lucas-eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
