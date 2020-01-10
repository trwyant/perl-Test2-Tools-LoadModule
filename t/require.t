package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::RequireModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}

use lib qw{ inc };
use My::Module::Test qw{ -inc cant_locate CHECK_MISSING_INFO };

use constant REQUIRE_MODULE_OK	=> "${CLASS}::require_module_ok";

my $file = __FILE__;	# So we can interpolate it.

{
    my $line;
    like
	intercept {
	    require_module_ok( $CLASS ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "Require $CLASS";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	"Require previously-loaded module $CLASS";
}

{
    my $line;
    my $module = 'Present';

    like
	intercept {
	    require_module_ok( $module, "Load $module" ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "Load $module";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	"Require not-previously-loaded module $module";
    last;
}

{
    local $@ = 'Ignore this';
    my $line;

    like
	intercept {
	    require_module_ok( undef ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> CLASS->MODNAME_UNDEF;
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	'Undefined module name';
}

{
    my $module = 'Bogus0';
    my $line;

    like
	intercept {
	    require_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "Require $module";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	"Require unloadable module $module";
}

{
    my $module = 'Bogus0';
    my $line;

    like
	intercept {
	    require_module_ok( $module, undef, '-EE' ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "Require $module";
		call info	=> array {
		    item object {
			call details	=> cant_locate( $module );
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	"Require unloadable module $module, with eval error";
}

{
    my $module = 'Bogus0';
    my $line;

    like
	intercept {
	    require_module_ok( $module, undef, '-EE', 'Fubar' ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "Require $module";
		call info	=> array {
		    item object {
			call details	=> cant_locate( $module );
		    };
		    item object {
			call details	=> 'Fubar';
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> REQUIRE_MODULE_OK;
	    };

	    end;
	},
	"Require unloadable module $module, with extra diagnostic";
}

done_testing;

1;

# ex: set textwidth=72 :
