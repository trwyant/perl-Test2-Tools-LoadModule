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

use constant SUB_NAME	=> "${CLASS}::use_ok";

my $p = {
    perl_import_semantics	=> 1,
};
my $line;

{
    like
	intercept {
	    use_ok CLASS; $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( $p, CLASS );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use previously-loaded module $CLASS, no import";
}


{
    my $module = 'Present';

    like
	intercept {
	    use_ok $module; $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( $p, $module );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Use not-previously-loaded module $module, with default import";

    imported_ok( 'and_accounted_for' );
    not_imported_ok( 'under_the_tree' );
}

{
    my $module = 'Present';
    my @import = qw{ under_the_tree };
    like
	intercept {
	    use_ok( $module, @import ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( $module, undef, \@import );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use now-loaded module $module, with explicit import";

    imported_ok( 'under_the_tree' );
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    use_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $p, $module );
		call info	=> array {
		    item object {
			call details	=> "Tried to use '$module'.";
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
	"Load unloadable module $module, with load error diagnostic";
}


{
    my $module = 'BogusVersion';
    my $version = 99999;

    like
	intercept {
	    use_ok( $module, $version ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $p, $module, $version );
		call info	=> array {
		    item object {
			call details	=> "Tried to use '$module'.";
		    };
		    item object {
			call details	=>
				match qr<\AError:  $module version $version required\b>sm;
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
	    use_ok( $module, @import ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval(
		    $module, undef, \@import );
		call info	=> array {
		    item object {
			call details	=> "Tried to use '$module'.";
		    };
		    item object {
			call details	=>
				match qr<\AError:  "@import" is not exported\b>sm;
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
