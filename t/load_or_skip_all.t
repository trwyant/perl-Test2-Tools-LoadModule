package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( qw{ :all :private } );
}

use lib qw{ inc };
use My::Module::Test qw{
    -inc
    build_skip_reason
    cant_locate
    CHECK_MISSING_INFO
};

use constant SUB_NAME	=> "${CLASS}::load_module_or_skip_all";
use constant SUB_NAME_P	=> "${CLASS}::load_module_p_or_skip_all";

my $line;

{
    like
	intercept {
	    load_module_or_skip_all $CLASS;
	},
	array {
	    end;
	},
	"use $CLASS (already loaded)";
}


{
    my $module = 'Present';

    not_imported_ok 'and_accounted_for';

    like
	intercept {
	    load_module_p_or_skip_all $module;
	},
	array {
	    end;
	},
	"use $module (not previously loaded, Perl semantics)";

    imported_ok 'and_accounted_for';
}


{
    my $module	= 'Bogus0';

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module (not loadable) skips";
}


{
    my $module	= 'BogusVersion';
    my $version = 99999;

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module, $version;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module, $version );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module $version (version error) skips";
}


{
    my $module = 'BogusVersion';
    my @import = qw{ no_such_export };

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module, undef, \@import;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module, undef, \@import );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module qw{ @import } (import error) skips";
}


done_testing;


1;

# ex: set textwidth=72 :
