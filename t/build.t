package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( ':private' );
}


sub perl_import_semantics {
    return __get_hint_hash( 1 )->{perl_import_semantics} || 0;
}

is __build_load_eval( {}, 'Fubar' ),
    'use Fubar ()',
    'Module name only, load semantics';

is __build_load_eval( {}, Smart => 86 ),
    'use Smart 86 ()',
    'Module and version, load semantics';

is __build_load_eval( {}, Nemo => undef, [] ),
    'use Nemo',
    'Module and empty import list, load semantics';

is __build_load_eval( {}, Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list, load semantics';

is __build_load_eval( {}, Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list, load semantics';

is __build_load_eval( { perl_import_semantics => 1 }, 'Fubar' ),
    'use Fubar',
    'Module name only, Perl semantics';

is __build_load_eval( { perl_import_semantics => 1 }, Smart => 86 ),
    'use Smart 86',
    'Module and version, Perl semantics';

is __build_load_eval( { perl_import_semantics => 1 },
	Nemo => undef, [] ),
    'use Nemo ()',
    'Module and empty import list, Perl semantics';

is __build_load_eval( { perl_import_semantics => 1 },
	Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp }',
    'Module and explicit import list, Perl semantics';

is __build_load_eval( { perl_import_semantics => 1 },
	Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur }',
    'Module, version, and explicit export list, Perl semantics';

done_testing;

1;

# ex: set textwidth=72 :
