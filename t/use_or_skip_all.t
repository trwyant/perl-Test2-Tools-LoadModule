package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}

use lib qw{ inc };
use My::Module::Test qw{ -inc cant_locate CHECK_MISSING_INFO };

my $file = __FILE__;	# So we can interpolate it.

{
    my $name = "use $CLASS (already loaded)";
    my $ran;
    subtest $name => sub {
	use_module_or_skip_all $CLASS;
	pass $name;
	$ran = 1;
    };
    ok $ran, "$name did not skip";
}

{
    my $module = 'Present';
    my $name	= "use $module (not previously loaded)";
    my $ran;
    subtest $name => sub {
	use_module_or_skip_all $module;
	pass $name;
	$ran = 1;
    };
    ok $ran, "$name did not skip";
}

{
    my $module	= 'Bogus0';
    my $name	= "use $module (not loadable)";
    my $ran;
    subtest $name => sub {
	use_module_or_skip_all $module;
	fail $name;
    };
    ok !$ran, "$name skipped";
}

{
    my $module = 'BogusVersion';
    my $version = 99999;
    my $name = "use $module $version (version error)";
    my $ran;
    subtest $name => sub {
	use_module_or_skip_all $module, $version;
	fail $name;
	$ran = 1;
    };
    ok !$ran, "$name skipped";
}

done_testing;

1;

# ex: set textwidth=72 :
