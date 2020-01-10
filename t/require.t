package main;

use 5.008001;

use strict;
use warnings;

use Carp qw{ croak };
use Test2::V0 -target => 'Test2::Tools::RequireModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import();
}
use Test2::Util qw{ pkg_to_file };

BEGIN {
    # This is deeper magic than I like, but it lets me get rid of
    # Test::Without::Module as a testing dependency. The idea is that
    # Test2::Tools::RequireModule only sees t/lib/, but everyone else
    # can still load whatever they want. Modules already loaded at this
    # point will still appear to be loaded, no matter who requests them.
    unshift @INC,
	sub {
	    my $lvl = 0;
	    while ( my $pkg = caller $lvl++ ) {
		CLASS eq $pkg
		    or next;
		my $fh;
		open $fh, '<', "t/lib/$_[1]"
		    and return ( \'', $fh );
		croak "Can't locate $_[1] in \@INC";
	    }
	    return;
	},
}

use constant REQUIRE_MODULE_OK	=> "${CLASS}::require_module_ok";

# NOTE that if there are no diagnostics, info() returns undef, not an
# empty array. I find this nowhere documented, so I am checking for
# both.
use constant CHECK_MISSING_INFO	=> in_set( undef, array{ end; } );

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
    my $fn = pkg_to_file( $module );
    my $line;

    like
	intercept {
	    require_module_ok( $module, undef, '-EE' ); $line = __LINE__;
	},
	array {

	    # NOTE that when I implemented in terms of ok() there was a
	    # "Failed test" Diag, which disappeared when I changed the
	    # implementation to fail_and_release(). This change
	    # converted the additional diagnostics to info, which
	    # consisted of an array of Test2::EventFacet::Info objects.
	    # The only way I figured this out was by reading
	    # Test2::API::Context. Sigh.
	    event Fail => sub {
		call name	=> "Require $module";
		call info	=> array {
		    item object {
			call details	=>
				match qr<\ACan't locate $fn in \@INC\b>sm;
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
    my $fn = pkg_to_file( $module );
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
			call details	=>
				match qr<\ACan't locate $fn in \@INC\b>sm;
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
