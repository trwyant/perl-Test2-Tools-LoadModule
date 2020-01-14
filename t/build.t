package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( ':private' );
}


BEGIN {
    note 'Make sure this works in a BEGIN block';

    ok ! __perl_import_semantics(), 'Perl import semantics are off';

    use Test2::Tools::LoadModule '-perl-import-semantics';

    ok __perl_import_semantics(), 'Perl import semantics are now on';

    note 'End of BEGIN block';
}

ok ! __perl_import_semantics(), 'Perl import semantics are now off';

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

{
    note 'Beginning of block';

    ok ! __perl_import_semantics(), 'Perl import semantics are still off';

    is __build_load_eval( 'Fubar' ),
	'use Fubar ()',
	'Module name only, still load semantics inside new block';

    use Test2::Tools::LoadModule '-perl-import-semantics';

    ok __perl_import_semantics(), 'Perl import semantics are now on';

    is __build_load_eval( 'Fubar' ),
	'use Fubar',
	'Module name only, Perl semantics';

    is __build_load_eval( Smart => 86 ),
	'use Smart 86',
	'Module and version, Perl semantics';

    is __build_load_eval( Nemo => undef, [] ),
	'use Nemo ()',
	'Module and empty import list, Perl semantics';

    is __build_load_eval( Howard => undef, [ qw{ larry moe shemp } ] ),
	'use Howard qw{ larry moe shemp }',
	'Module and explicit import list, Perl semantics';

    is __build_load_eval( Dent => 42, [ qw{ Arthur } ] ),
	'use Dent 42 qw{ Arthur }',
	'Module, version, and explicit export list, Perl semantics';

    no Test2::Tools::LoadModule '-perl-import-semantics';

    ok ! __perl_import_semantics(), 'Perl import semantics are now off';

    is __build_load_eval( 'Fubar' ),
	'use Fubar ()',
	'Module name only, back to load semantics';

    use Test2::Tools::LoadModule '-perl-import-semantics';

    ok __perl_import_semantics(), 'Perl import semantics are now on';

    is __build_load_eval( 'Fubar' ),
	'use Fubar',
	'Module name only, back to Perl semantics';

    note 'End of block';
}

ok ! __perl_import_semantics(),
    'Perl import semantics are now off after block';

is __build_load_eval( 'Fubar' ),
    'use Fubar ()',
    'Module name only, back to load semantics after block';

done_testing;

1;

# ex: set textwidth=72 :
