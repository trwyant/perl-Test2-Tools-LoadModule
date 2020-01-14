package main;

use 5.010;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule '-perl-import-semantics';

load_module_or_skip_all 'Test::CPAN::Changes';

changes_file_ok( Changes => { next_token => 'next_release' } );

done_testing;

1;

# ex: set textwidth=72 :
