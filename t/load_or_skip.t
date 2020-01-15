package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}

# plan skip_all => 'TODO - problem with my -inc code';

use lib qw{ inc };
use My::Module::Test qw{ -inc cant_locate CHECK_MISSING_INFO };


{
    my $name = "use $CLASS (already loaded)";
    my $ran;
    SKIP: {
	load_module_or_skip $CLASS;
	pass $name;
	$ran = 1;
    };
    ok $ran, "$name did not skip";
}


{
    my $module = 'Present';
    my $name	= "use $module (not previously loaded, Perl semantics)";
    my $ran;
    SKIP: {
	load_module_p_or_skip $module;
	pass $name;
	$ran = 1;
    };
    ok $ran, "$name did not skip";
    imported_ok 'and_accounted_for';
}


{
    my $module	= 'Bogus0';
    my $name	= "use $module (not loadable)";
    my $ran;
    SKIP: {
	load_module_or_skip $module;
	fail $name;
    };
    ok !$ran, "$name skipped";
}


{
    my $module = 'BogusVersion';
    my $version = 99999;
    my $name = "use $module $version (version error)";
    my $ran;
    SKIP: {
	load_module_or_skip $module, $version;
	fail $name;
	$ran = 1;
    };
    ok !$ran, "$name skipped";
}


{
    my $module = 'BogusVersion';
    my @import = qw{ no_such_export };
    my $name = "use $module qw{ @import } (import error)";
    my $ran;
    SKIP: {
	load_module_or_skip $module, undef, \@import;
	fail $name;
	$ran = 1;
    };
    ok !$ran, "$name skipped";
}


done_testing;

1;

# ex: set textwidth=72 :
