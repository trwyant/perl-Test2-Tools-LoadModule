package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( qw{ __build_load_eval } );
}
use Test2::Tools::LoadModule;

is __build_load_eval( 'Fubar' ),
    'use Fubar ()',
    'Module name only';

is __build_load_eval( Smart => 86 ),
    'use Smart 86 ()',
    'Module and version';

is __build_load_eval( Nemo => undef, [] ),
    'use Nemo',
    'Module and empty import list';

is __build_load_eval( Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list';

is __build_load_eval( Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list';

done_testing;

1;

# ex: set textwidth=72 :
