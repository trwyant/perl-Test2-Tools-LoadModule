package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( qw{ :more :private } );
}

use lib qw{ inc };
use My::Module::Test qw{ -inc cant_locate CHECK_MISSING_INFO };

use constant SUB_NAME	=> "${CLASS}::require_ok";

my $line;

{
    like
	intercept {
	    require_ok( CLASS ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "require $CLASS;";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Require previously-loaded module $CLASS";
}


{
    my $module = 'Present';
    like
	intercept {
	    require_ok( $module ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "require $module;";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Require not-previously-loaded module $module";
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    require_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "require $module;";
		call info	=> array {
		    item object {
			call details	=> "Tried to require '$module'.";
		    };
		    item object {
			call details	=> cant_locate( $module, 'Error:  ' );
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
	"Require unloadable module $module";
}


done_testing;

1;

# ex: set textwidth=72 :
