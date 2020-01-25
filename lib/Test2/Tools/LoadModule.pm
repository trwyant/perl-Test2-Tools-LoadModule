package Test2::Tools::LoadModule;

use 5.008001;

use strict;
use warnings;

use Carp;
use Exporter 5.567;	# Comes with Perl 5.8.1.
use Getopt::Long 2.34;	# Comes with Perl 5.8.1.
use Test2::API ();
use Test2::Util ();

use base qw{ Exporter };

our $VERSION = '0.000_012';
$VERSION =~ s/ _ //smxg;

{
    my @test2 = qw{
	load_module_ok
	load_module_p_ok
	load_module_or_skip
	load_module_p_or_skip
	load_module_or_skip_all
	load_module_p_or_skip_all
    };

    my @more = qw{
	require_ok
	use_ok
    };

    my @private = qw{
	__build_load_eval
	__get_hint_hash
	DEFAULT_LOAD_ERROR
	HINTS_AVAILABLE
	TEST_MORE_ERROR_CONTEXT
	TEST_MORE_LOAD_ERROR
    };

    our @EXPORT_OK = ( @test2, @more, @private );

    our %EXPORT_TAGS = (
	all		=> [ @test2, @more ],
	default	=> \@test2,
	more	=> \@more,
	private	=> \@private,
	test2	=> \@test2,
    );

    our @EXPORT = @{ $EXPORT_TAGS{default} };	## no critic (ProhibitAutomaticExportation)
}

use constant ARRAY_REF		=> ref [];
use constant HASH_REF		=> ref {};

use constant HINTS_AVAILABLE	=> $] ge '5.010';

# The following cribbed shamelessly from version::regex 0.9924,
# after being munged to suit by tools/version_regex 0.000_010.
# This technical debt is incurred to avoid having to require a version
# of the version module large enough to export the is_lax() subroutine.
use constant LAX_VERSION	=> qr/(?x: (?x:
	v (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+)+ (?-x:_[0-9]+)? )?
	|
	(?-x:[0-9]+)? (?-x:\.[0-9]+){2,} (?-x:_[0-9]+)?
    ) | (?x: (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+) | \. )? (?-x:_[0-9]+)?
	|
	(?-x:\.[0-9]+) (?-x:_[0-9]+)?
    ) )/;

use constant TEST_MORE_ERROR_CONTEXT	=> q/Tried to %s '%s'./;
use constant TEST_MORE_LOAD_ERROR	=> 'Error:  %s';
use constant TEST_MORE_OPT		=> {
    load_error	=> TEST_MORE_LOAD_ERROR,
};

sub load_module_ok (@) {
    my @args = _validate_args( @_ );
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( @args );
    $ctx->release();
    return $rslt;
}

sub load_module_p_ok (@) {
    my @args = _validate_args( @_ );
    $args[0]{perl_import_semantics} = 1;
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( @args );
    $ctx->release();
    return $rslt;
}

sub _load_module_ok {
    my ( $opt, $module, $version, $import, $name, @diag ) = @_;

    local $@ = undef;

    my $eval = __build_load_eval( $opt, $module, $version, $import );

    defined $name
	or $name = $eval;

    my $ctx = Test2::API::context();

    _eval_in_pkg( $eval, $ctx->trace()->call() )
	and return $ctx->pass_and_release( $name );

    chomp $@;

    $opt->{load_error}
	and push @diag, sprintf $opt->{load_error}, $@;

    return $ctx->fail_and_release( $name, @diag );
}


sub load_module_or_skip (@) {	## no critic (RequireFinalReturn)
    my ( $opt, $module, $version, $import, $name, $num ) = _validate_args( @_ );

    _load_module( $opt, $module, $version, $import )
	and return;

    my $ctx = Test2::API::context();
    _or_skip( $opt, $module, $version, $import, $name, $num );
    $ctx->release();
    no warnings qw{ exiting };
    last SKIP;
}


sub load_module_p_or_skip (@) {	## no critic (RequireFinalReturn)
    my ( $opt, $module, $version, $import, $name, $num ) = _validate_args( @_ );
    $opt->{perl_import_semantics} = 1;

    _load_module( $opt, $module, $version, $import )
	and return;

    my $ctx = Test2::API::context();
    _or_skip( $opt, $module, $version, $import, $name, $num );
    $ctx->release();
    no warnings qw{ exiting };
    last SKIP;
}

sub load_module_or_skip_all (@) {
    my ( $opt, $module, $version, $import, $name ) = _validate_args( @_ );

    _load_module( $opt, $module, $version, $import )
	and return;

    my $ctx = Test2::API::context();
    _or_skip_all( $opt, $module, $version, $import, $name );
    $ctx->release();
    return;
}


sub load_module_p_or_skip_all (@) {
    my ( $opt, $module, $version, $import, $name ) = _validate_args( @_ );
    $opt->{perl_import_semantics} = 1;

    _load_module( $opt, $module, $version, $import )
	and return;

    my $ctx = Test2::API::context();
    _or_skip_all( $opt, $module, $version, $import, $name );
    $ctx->release();
    return;
}


sub _load_module {
    my ( $opt, $module, $version, $import ) = @_;

    local $@ = undef;

    my $eval = __build_load_eval( $opt, $module, $version, $import );

    return _eval_in_pkg( $eval, _get_call_info() )
}

sub _or_skip {
    my ( $opt, $module, $version, $import, $name, $num ) = @_;
    defined $name
	or $name = sprintf 'Unable to %s',
	    __build_load_eval( $opt, $module, $version, $import );
    defined $num
	and $num =~ m/ [^0-9] /smx
	and croak 'Number of skipped tests must be an unsigned integer';
    $num ||= 1;
    my $ctx = Test2::API::context();
    $ctx->skip( 'skipped test', $name ) for 1 .. $num;
    $ctx->release();
    return;
}

sub _or_skip_all {
    my ( $opt, $module, $version, $import, $name ) = @_;
    defined $name
	or $name = sprintf 'Unable to %s',
	    __build_load_eval( $opt, $module, $version, $import );
    my $ctx = Test2::API::context();
    $ctx->plan( 0, SKIP => $name );
    $ctx->release();
    return;
}

{
    my $psr = Getopt::Long::Parser->new();
    $psr->configure( qw{ posix_default } );

    # Because we want to work with Perl 5.8.1 we are limited to
    # Getopt::Long 2.34, and therefore getoptions(). So we expect the
    # arguments to be in a suitably-localized @ARGV. The optional
    # argument is a reference to a hash into which we place the option
    # values. If omitted, we create a reference to a new hash. Either
    # way the hash reference gets returned.
    sub _parse_import_opts {
	my ( $opt ) = @_;
	$opt ||= {};
	$psr->getoptions( $opt, qw{
		load_error=s
	    },
	)
	    or croak "Invalid import option";
	if ( $opt->{load_error} ) {
	    $opt->{load_error} =~ m/ ( %+ ) [ #0+-]* [0-9]* s /smx
		and length( $1 ) % 2
		or $opt->{load_error} = '%s';
	}
	return $opt;
    }
}

sub import {	## no critic (RequireArgUnpacking,ProhibitBuiltinHomonyms)
    ( my $class, local @ARGV ) = @_;	# See _parse_import_opts
    if ( @ARGV ) {
	my %opt;
	_parse_import_opts( \%opt );
	if ( HINTS_AVAILABLE ) {
	    $^H{ _make_pragma_key() } = $opt{$_} for keys %opt;
	} else {
	    keys %opt
		and carp "Import options ignored under Perl $]";
	}
	@ARGV
	    or return;
    }
    return $class->export_to_level( 1, $class, @ARGV );
}

sub require_ok ($) {
    my ( $module ) = @_;
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( TEST_MORE_OPT,
	$module, undef, undef, "require $module;",
	sprintf( TEST_MORE_ERROR_CONTEXT, require => $module ),
    );
    $ctx->release();
    return $rslt;
}

sub use_ok ($;@) {
    my ( $module, @arg ) = @_;
    my $version = ( defined $arg[0] && $arg[0] =~ LAX_VERSION ) ?
	shift @arg : undef;
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( TEST_MORE_OPT,
	$module, $version, \@arg, undef,
	sprintf( TEST_MORE_ERROR_CONTEXT, use => $module ),
    );
    $ctx->release();
    return $rslt;
}

sub _make_pragma_key {
    return join '', __PACKAGE__, '/', $_;
}

{
    use constant DEFAULT_LOAD_ERROR	=> '%s';

    my %default_hint = (
	load_error	=> DEFAULT_LOAD_ERROR,
    );

    sub __get_hint_hash {
	my ( $level ) = @_;
	$level ||= 0;
	my $hint_hash = ( caller( $level ) )[ 10 ];
	my %rslt = %default_hint;
	if ( HINTS_AVAILABLE ) {
	    foreach ( keys %{ $hint_hash } ) {
		my ( $hint_pkg, $hint_key ) = split qr< / >smx;
		__PACKAGE__ eq $hint_pkg
		    and $rslt{$hint_key} = $hint_hash->{$_};
	    }
	}
	return wantarray ? %rslt : \%rslt;
    }
}


sub __build_load_eval {
    my @arg = @_;
    HASH_REF eq ref $arg[0]
	or unshift @arg, {};
    my ( $opt, $module, $version, $import ) = @arg;
    my @eval = "use $module";

    defined $version
	and push @eval, $version;

    if ( $import && @{ $import } ) {
	push @eval, "qw{ @{ $import } }";
    } elsif ( $opt->{perl_import_semantics} xor defined $import ) {
	# Do nothing.
    } else {
	push @eval, '()';
    }

    return "@eval;";
}


sub _validate_args {
    local @ARGV = @_;
    my $opt = _parse_import_opts( scalar __get_hint_hash( 2 ) );
    my ( $module, $version, $import, $name, @diag ) = @ARGV;

    defined $module
	or croak 'Module name must be defined';

    if ( defined $version ) {
	$version =~ LAX_VERSION
	    or croak "Version '$version' is invalid";
    }

    not defined $import
	or ARRAY_REF eq ref $import
	or croak 'Import list must be an array reference, or undef';

    return ( $opt, $module, $version, $import, $name, @diag );
}


sub _eval_in_pkg {
    my ( $eval, $pkg, $file, $line ) = @_;

    my $e = <<"EOD";
package $pkg;
#line $line "$file"
$eval;
1;
EOD

    # We need the stringy eval() so we can mess with Perl's concept of
    # what the current file and line number are for the purpose of
    # formatting the exception, AND as a convenience to get symbols
    # imported.
    my $rslt = eval $e;	## no critic (ProhibitStringyEval)

    return $rslt;
}


sub _get_call_info {
    my $lvl = 0;
    while ( my @info = caller $lvl++ ) {
	__PACKAGE__ eq $info[0]
	    and next;
	$info[1] =~ m/ \A [(] eval \b /smx	# )
	    or return @info;
    }
    confess 'Bug - Unable to determine caller';
}


1;

__END__

=head1 NAME

Test2::Tools::LoadModule - Test whether a module can be successfully loaded.

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::LoadModule;
 
 load_module_ok 'My::Module';
 
 done_testing();

=head1 DESCRIPTION

This L<Test2::Tools|Test2::Tools> module tests whether a module can be
loaded, and optionally whether it has at least a given version and
exports specified symbols. It can also skip tests, or skip all tests,
based on these criteria.

L<Test2::Manual::Testing::Migrating|Test2::Manual::Testing::Migrating>
deals with migrating from L<Test::More|Test::More> to
L<Test2::V0|Test2::V0>. It states that instead of C<require_ok()> you
should simply use the C<require()> built-in, since a failure to load the
required module or file will cause the test script to fail anyway. The
same is said for C<use_ok()>.

In my perhaps-not-so-humble opinion this overlooks the fact that if you
can not load the module you are testing, it may make sense to abort not
just the individual test script but the entire test run. Put another
way, the absence of an analogue to L<Test::More|Test::More>'s
C<require_ok()> means there is no analogue to

 require_ok( 'My::Module' ) or BAIL_OUT();

This module restores that functionality.

B<Note> that if you are using this module with testing tools that are
not based on L<Test2::V0|Test2::V0> you may have to tweak the load order
of modules. I ran into this in the early phases of implementation, and
fixed it for my own use by initializing the testing system as late as
possible, but I can not promise that all such problems have been
eliminated.

=head1 SUBROUTINES

All subroutines documented below are exportable, either by name or using
one of the following tags:

=over

=item :all exports all public exports;

=item :default exports the default exports (i.e. :test2);

=item :more exports require_ok() and use_ok();

=item :test2 exports load_module_*(), and is the default.

=back

=head2 load_module_ok

 load_module_ok $module, $ver, $import, $name, @diag;

Prototype: C<($;$$$@)>.

This subroutine tests whether the specified module (B<not> file) can be
loaded. All arguments are optional but the first. The arguments are:

=over

=item $module - the module name

This is required, and must not be C<undef>.

=item $ver - the desired version number, or undef

If defined, the test fails if the installed module is not at least this
version. An exception is thrown if L<version|version> thinks the version
number is invalid.

If C<undef>, no version check is done.

=item $import - the import list as an array ref, or undef

This argument specifies the import list. C<undef> means not to import at
all, C<[]> means to import the default symbols, and a scalar or a
non-empty array reference mean to import the specified symbols.

=item $name - the test name, or undef

If C<undef>, the name defaults to the code used to load the module.
B<Note> that this code, and therefore the default name, may change
without notice.

=item @diag - the desired diagnostics

Diagnostics are only issued on failure.

=back

Argument validation failures are signalled by C<croak()>.

The module is loaded, and version checks and imports are done if
specified. The test passes if all these succeed, and fails otherwise.

B<Note> that any imports from the loaded module take place when this
subroutine is called, which is normally at run time. Imported
subroutines will be callable, provided you do not make use of prototypes
or attributes.

If you want anything imported from the loaded module to be available for
subsequent compilation (e.g. variables, subroutine prototypes) you will
need to put the call to this subroutine in a C<BEGIN { }> block:

 BEGIN { load_module_ok 'My::Module'; }

By default, C<$@> is appended to the diagnostics issued in the event of
a load failure. If you want to omit this, or embed the value in your own
text, see L<LOAD ERROR FORMATTING|/LOAD ERROR FORMATTING>, below.

=head2 load_module_p_ok

 load_module_p_ok $module, $ver, $import, $name, @diag;

This subroutine is the same as L<load_module_ok()|/load_module_ok>, but
Perl semantics are applied to the import list. That is, the value
C<undef> means to import the default symbols, and C<[]> means not to
call C<import()> at all.

=head2 load_module_or_skip

 load_module_or_skip $module, $ver, $import, $name, $num;

Prototype: C<($;$$$$)>.

This subroutine performs the same loading actions as
L<load_module_ok()|/load_module_ok>, but no tests are performed.
Instead, the specified number of tests is skipped if the load fails.

The arguments are the same as L<load_module_ok()|/load_module_ok>,
except that the fifth argument (C<$num> in the example) is the number of
tests to skip, defaulting to C<1>.

The C<$name> argument gives the skip message, and defaults to
C<"Unable to ..."> where the ellipsis is the code used to load the
module.

=head2 load_module_p_or_skip

 load_module_p_or_skip $module, $ver, $import, $name, $num;

This subroutine is the same as
L<load_module_or_skip()|/load_module_or_skip>, but Perl semantics are
applied to the import list. That is, the value C<undef> means to import
the default symbols, and C<[]> means not to call C<import()> at all.

=head2 load_module_or_skip_all

 load_module_or_skip_all $module, $ver, $import, $name;

Prototype: C<($;$$$)>.

This subroutine performs the same loading actions as
L<load_module_ok()|/load_module_ok>, but no tests are performed.
Instead, all tests are skipped if any part of the load fails.

The arguments are the same as L<load_module_ok()|/load_module_ok>,
except for the fact that diagnostics are not specified.

The C<$name> argument gives the skip message, and defaults to
C<"Unable to ..."> where the ellipsis is the code used to load the
module.

This subroutine can be called either at the top level or in a subtest,
but either way it B<must> be called before any actual tests in the file
or subtest.

=head2 load_module_p_or_skip_all

 load_module_p_or_skip_all $module, $ver, $import, $name;

This subroutine is the same as
L<load_module_or_skip_all()|/load_module_or_skip_all>, but Perl
semantics are applied to the import list. That is, the value C<undef>
means to import the default symbols, and C<[]> means not to call
C<import()> at all.

=head2 require_ok

 require_ok $module;

Prototype: C<($)>.

This subroutine is more or less the same as the L<Test::More|Test::More>
subroutine of the same name. It's actually a C<use()> that gets issued,
but without a version check or importing anything.

=head2 use_ok

 use_ok $module, @imports;
 use_ok $module, $version, @imports;

Prototype: C<($;@)>.

This subroutine is more or less the same as the L<Test::More|Test::More>
subroutine of the same name.

=head2 LOAD ERROR FORMATTING

By default, the C<load_module_*()> subroutines append the value of C<$@>
produced by the failure to the diagnostics. You can control the
presence and formatting of this by specifying the C<-load_error> option
as the first argumentZ<>(s) to the subroutine, or (under Perl
5.10.0 and above) in a C<use Test2::Tools::LoadModule> statement.

The value of this option is interpreted as follows:

=over

=item A string containing C<'%s'>

or anything that looks like an C<sprintf()> string substitution is
interpreted verbatim as the L<sprintf> format to use to format the
error;

=item Any other true value (e.g. C<1>)

specifies the default, C<'%s'>;

=item Any false value (e.g. C<0>)

specifies that C<$@> should not be appended to the diagnostics at all.

=back

For example, if you want your diagnostics to look like the
L<Test::More|Test::More> C<require_ok()> diagnostics, you can do
something like this:

 {	# Begin scope
   use Test2::Tools::LoadModule -load_error => 'Error:  %s';
   load_module_ok $my_module, undef, undef,
     "require $my_module;", "Tried to require '$my_module'.";
   ...
 }
 # -load_error reverts to whatever it was before.

If you want your code to work under Perl 5.8, you can equivalently do

 load_module_ok -load_error => 'Error:  %s',
     $my_module, undef, undef, "require $my_module;"
     "Tried to require '$my_module'.";

B<Note> that the options parse uses POSIX conventions. That is, options
must come before non-option arguments if any, and although (e.g.)
C<'--load_error=1'> will parse, C<'-load_error=1'> will not.

B<Note also> that, while you can specify options on your initial load,
if you do so you must specify your desired imports explicitly, as (e.g.)

 use Test2::Tools::LoadModule
    -load_error => 'Bummer! %s', ':default';

=head1 SEE ALSO

L<Test::More|Test::More>

L<Test2::V0|Test2::V0>

L<Test2::Manual::Testing::Migrating|Test2::Manual::Testing::Migrating>

L<Test2::Plugin::BailOnFail|Test2::Plugin::BailOnFail>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
