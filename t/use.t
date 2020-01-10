package main;

use 5.008001;

use strict;
use warnings;

use Carp qw{ croak };
use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}

use lib qw{ inc };
use My::Module::Test qw{ -inc cant_locate CHECK_MISSING_INFO };

use constant USE_MODULE_OK	=> "${CLASS}::use_module_ok";

my $file = __FILE__;	# So we can interpolate it.

{
    my $line;
    like
	intercept {
	    use_module_ok( $CLASS ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $CLASS";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use previously-loaded module $CLASS";
}

{
    my $line;
    my $module = 'Present';

    like
	intercept {
	    use_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $module";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use not-previously-loaded module $module";
}

imported_ok qw{ and_accounted_for };
not_imported_ok qw{ under_the_tree };	# Should not have this yet.

{
    my $line;
    my $module = 'Present';

    like
	intercept {
	    use_module_ok( $module, 'under_the_tree' ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $module qw{ under_the_tree }";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use previously-loaded module $module with export list";
}

imported_ok qw{ under_the_tree };

{
    local $@ = 'Ignore this';
    my $line;

    like
	intercept {
	    use_module_ok( undef ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> CLASS->MODNAME_UNDEF;
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	'use with undefined module name';
}

{
    my $module = 'Bogus0';
    my $line;

    like
	intercept {
	    use_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "use $module";
		call info	=> array {
		    item object {
			call details	=> cant_locate( $module );
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use unloadable module $module";
}

{
    my $module = 'BogusVersion';
    my $version = 99999;
    my $line;

    like
	intercept {
	    use_module_ok( $module, $version ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "use $module $version";
		call info	=> array {
		    item object {
			call details	=>
				match qr<\A$module version $version required\b>sm;
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use module $module version $version";
}

done_testing;

1;

# ex: set textwidth=72 :
