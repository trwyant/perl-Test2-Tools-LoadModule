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
    subtest $name => sub {
	use_module_or_skip_all $CLASS;
	pass $name;
    };
}

{
    my $module = 'Present';
    my $name	= "use $module (not previously loaded)";
    subtest $name => sub {
	use_module_or_skip_all $module;
	pass $name;
    };
}

{
    my $module	= 'Bogus0';
    my $name	= "use $module (not loadable)";
    subtest $name => sub {
	use_module_or_skip_all $module;
	fail $name;
    };
}

{
    my $module = 'BogusVersion';
    my $version = 99999;
    my $name = "use $module $version (version error)";
    subtest $name => sub {
	use_module_or_skip_all $module, $version;
	fail $name;
    };
}

done_testing;

1;

# ex: set textwidth=72 :
