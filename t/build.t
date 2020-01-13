package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}
use Test2::Tools::LoadModule;

*build_load_eval = \&Test2::Tools::LoadModule::__build_load_eval;

is build_load_eval( 'Fubar' ),
    'use Fubar',
    'Module name only';

is build_load_eval( Smart => 86 ),
    'use Smart 86',
    'Module and version';

is build_load_eval( Nemo => undef, [] ),
    'use Nemo ()',
    'Module and empty import list';

is build_load_eval( Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list';

is build_load_eval( Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list';

done_testing;

1;

# ex: set textwidth=72 :
