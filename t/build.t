package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( ':private' );
}

use constant P => { perl_import_semantics => 1 };

is __build_load_eval( 'Fubar' ),
    'use Fubar ()',
    'Module name only, load semantics';

is __build_load_eval( Smart => 86 ),
    'use Smart 86 ()',
    'Module and version, load semantics';

is __build_load_eval( Nemo => undef, [] ),
    'use Nemo',
    'Module and empty import list, load semantics';

is __build_load_eval( Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list, load semantics';

is __build_load_eval( Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list, load semantics';

is __build_load_eval( P, 'Fubar' ),
    'use Fubar',
    'Module name only, Perl semantics';

is __build_load_eval( P, Smart => 86 ),
    'use Smart 86',
    'Module and version, Perl semantics';

is __build_load_eval( P, Nemo => undef, [] ),
    'use Nemo ()',
    'Module and empty import list, Perl semantics';

is __build_load_eval( P,
	Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list, Perl semantics';

is __build_load_eval( P,
	Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list, Perl semantics';

done_testing;

1;

# ex: set textwidth=72 :
