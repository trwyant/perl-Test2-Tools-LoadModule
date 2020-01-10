package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::BailOnFail;

# NOTE that this mess is why I think this is a useful module.
BEGIN {
    local $@ = undef;
    ok eval {
	require Test2::Tools::LoadModule;
	1;
    }, 'Can load Test2::Tools::LoadModule';

    Test2::Tools::LoadModule->import();
}

imported_ok qw{ require_module_ok use_module_ok };

done_testing;

1;

# ex: set textwidth=72 :
