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

use constant SUB_NAME	=> "${CLASS}::load_module_ok";

my $line;


{
    like
	intercept {
	    load_module_ok( $CLASS ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $CLASS";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS";
}


{
    like
	intercept {
	    load_module_ok( $CLASS, 0 ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $CLASS 0";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS, version 0";
}


{
    like
	intercept {
	    load_module_ok( $CLASS, undef, [] ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $CLASS ()";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS, with import";
}


{
    my $module = 'Present';
    like
	intercept {
	    load_module_ok( $module, undef, undef, "Load $module" ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "Load $module";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-unloaded module $module, with default import";

    imported_ok( 'and_accounted_for' );
    not_imported_ok( 'under_the_tree' );
}

{
    my $module = 'Present';
    like
	intercept {
	    load_module_ok( $module, undef, [ 'under_the_tree' ] ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "use $module qw{ under_the_tree }";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load now-loaded module $module, with explicit import";

    imported_ok( 'under_the_tree' );
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    load_module_ok( $module ); $line = __LINE__;
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
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, with eval error";
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    load_module_ok( $module, undef, undef, undef, [ 'Fubar' ] ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "use $module";
		call info	=> array {
		    item object {
			call details	=> 'Fubar';
		    };
		    item object {
			call details	=> cant_locate( $module );
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, with extra diagnostic";
}


{
    my $module = 'BogusVersion';
    my $version = 99999;

    like
	intercept {
	    load_module_ok( $module, $version ); $line = __LINE__;
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
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load $module, with too-high version $version";
}


{
    my $module = 'BogusVersion';
    my @import = qw{ no_such_import };

    like
	intercept {
	    load_module_ok( $module, undef, \@import ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "use $module qw{ @import }";
		call info	=> array {
		    item object {
			call details	=>
				match qr<\A"@import" is not exported\b>sm;
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load $module, with non-existent import";
}



done_testing;

1;

# ex: set textwidth=72 :
