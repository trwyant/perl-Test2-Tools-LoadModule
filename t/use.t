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

use constant USE_MODULE_OK	=> "${CLASS}::use_module_ok";

# NOTE that if there are no diagnostics, info() returns undef, not an
# empty array. I find this nowhere documented, so I am checking for
# both.
use constant CHECK_MISSING_INFO	=> in_set( undef, array{ end; } );

my $file;

BEGIN {
    $file = __FILE__;	# So we can interpolate it.
}

BEGIN {
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

BEGIN {
    my $line;
    my $module = 'Present';

    like
	intercept {
	    use_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name		=> "use $module";
		call info		=> CHECK_MISSING_INFO;
		prop file		=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line		=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use not-previously-loaded module $module";
}

BEGIN {
    imported_ok qw{ and_accounted_for };
    not_imported_ok qw{ under_the_tree };	# Should not have this yet.
}

BEGIN {
    my $line;
    my $module = 'Present';

    like
	intercept {
	    use_module_ok( $module, 'under_the_tree' ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name		=> "use $module qw{ under_the_tree }";
		call info		=> CHECK_MISSING_INFO;
		prop file		=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line		=> $line;
		prop subname	=> USE_MODULE_OK;
	    };

	    end;
	},
	"use previously-loaded module $module with export list";
}

BEGIN {
    imported_ok qw{ under_the_tree };
}

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
    my $fn = pkg_to_file( $module );
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
			call details	=>
				match qr<\ACan't locate $fn in \@INC\b>sm;
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
