use strict;
use warnings;

use MandatoAberto;

my $app = MandatoAberto->apply_default_middlewares(MandatoAberto->psgi_app);
$app;