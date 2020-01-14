package main;

use 5.006002;

use strict;
use warnings;

use Test2::Tools::LoadModule '-perl-import-semantics';

load_module_or_skip_all 'Test::Kwalitee';

-f 'Debian_CPANTS.txt'		# Don't know what this is,
    and unlink 'Debian_CPANTS.txt';	# but _I_ didn't order it.

1;

# ex: set textwidth=72 :
