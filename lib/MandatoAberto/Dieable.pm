package MandatoAberto::Dieable;

use utf8;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/die_with die_with_reason/;

sub die_with ($) {
    die { msg_id => shift };
}

sub die_with_reason ($$) {
    die { msg_id => shift, reason => shift };
}

1;
