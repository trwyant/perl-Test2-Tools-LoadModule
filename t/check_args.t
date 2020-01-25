package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule qw{ :all :private };

my $line;

foreach my $sub ( qw{
    load_module_ok
    load_module_p_ok
    load_module_or_skip
    load_module_p_or_skip
    load_module_or_skip_all
    load_module_p_or_skip_all
    require_ok
    use_ok
    } ) {

    my $code = __PACKAGE__->can( $sub );

    is
	dies { $line = __LINE__; $code->() },
	make_msg( ERR_MODULE_UNDEF ),
	"$sub() requires at least a module name";
}

{
    my $version = 'plugh';
    my $vers_err = sprintf ERR_VERSION_BAD, $version;

    foreach my $sub ( qw{
	load_module_ok
	load_module_p_ok
	load_module_or_skip
	load_module_p_or_skip
	load_module_or_skip_all
	load_module_p_or_skip_all
	} ) {

	my $code = __PACKAGE__->can( $sub );

	is
	    dies { $line = __LINE__; $code->( -fubar => __PACKAGE__ ) },
	    make_msg( 'Unknown option: fubar' ),
	    "$sub() considers '-fubar' a bad option";

	is
	    dies { $line = __LINE__; $code->( __PACKAGE__, $version ) },
	    make_msg( $vers_err ),
	    "$sub() considers '$version' a bad version";

	is
	    dies { $line = __LINE__; $code->( __PACKAGE__, undef, {} ) },
	    make_msg( ERR_IMPORT_BAD ),
	    "$sub() considers {} a bad import list";
    }
}


foreach my $sub ( qw{
    load_module_or_skip
    load_module_p_or_skip
    } ) {

    my $code = __PACKAGE__->can( $sub );

    is
	dies { $line = __LINE__; $code->( __PACKAGE__, undef, undef,
		undef, 'plugh' ) },
	make_msg( ERR_SKIP_NUM_BAD ),
	"$sub() requires an unsigned integer skip number";

    is
	dies { $line = __LINE__; $code->( __PACKAGE__, undef, undef,
		undef, undef, undef ) },
	make_msg( "$sub() takes at most 5 arguments" ),
	"$sub() takes at most 5 arguments";
}


foreach my $sub ( qw{
    load_module_or_skip_all
    load_module_p_or_skip_all
    } ) {

    my $code = __PACKAGE__->can( $sub );

    is
	dies { $line = __LINE__; $code->( __PACKAGE__, undef, undef,
		undef, undef ) },
	make_msg( "$sub() takes at most 4 arguments" ),
	"$sub() takes at most 4 arguments";
}


done_testing;

sub make_msg {
    my ( $msg ) = @_;
    return sprintf "%s at %s line %d.\n", $msg, __FILE__, $line;
}

1;

# ex: set textwidth=72 :
