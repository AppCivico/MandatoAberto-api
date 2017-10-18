package MandatoAberto::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

use MandatoAberto::SchemaConnected qw(get_connect_info);

__PACKAGE__->config(
    schema_class => 'MandatoAberto::Schema',

    connect_info => get_connect_info(),
);

=head1 NAME

MandatoAberto::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<MandatoAberto>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<MandatoAberto::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.65

=head1 AUTHOR

lucas-eokoe

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
