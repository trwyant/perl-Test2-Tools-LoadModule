package Test2::Tools::LoadModule;

use 5.008001;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };
use Test2::API ();
use Test2::Util ();

our $VERSION = '0.000_002';

our @EXPORT =	## no critic (ProhibitAutomaticExportation)
qw{
    require_module_ok
    use_module_ok
    use_module_or_skip_all
};

our @EXPORT_OK = @EXPORT;

our %EXPORT_TAGS = (
    all	=> \@EXPORT_OK,
);

use constant MODNAME_UNDEF	=> 'Module name must be defined';

# The following cribbed shamelessly from version::regex, after being
# munged to suit by tools/version_regex
use constant LAX_VERSION	=> qr/(?x: (?x:
	v (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+)+ (?-x:_[0-9]+)? )?
	|
	(?-x:[0-9]+)? (?-x:\.[0-9]+){2,} (?-x:_[0-9]+)?
    ) | (?x: (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+) | \. )? (?-x:_[0-9]+)?
	|
	(?-x:\.[0-9]+) (?-x:_[0-9]+)?
    ) )/;

sub require_module_ok ($;$@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $module, $name, @diag ) = @_;

    local $@ = undef;

    my $ctx = Test2::API::context();

    defined $module
	or return $ctx->fail_and_release( MODNAME_UNDEF );

    defined $name
	and '' ne $name
	or $name = "Require $module";

    my ( $pkg, $file, $line ) = $ctx->trace()->call();

    # We need the stringy eval() so we can mess with Perl's concept of
    # what the current file and line number are for the purpose of
    # formatting the exception.
    eval <<"EOD"	## no critic (ProhibitStringyEval)
package $pkg;
#line $line "$file"
require $module;
1;
EOD
	and return $ctx->pass_and_release( $name );

    chomp $@;	# Note that this was localized above

    return $ctx->fail_and_release( $name, @diag, $@ );
}

sub use_module_ok ($;@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $module, @import ) = @_;

    local $@ = undef;

    my $ctx = Test2::API::context();

    defined $module
	or return $ctx->fail_and_release( MODNAME_UNDEF );

    my $use = _build_use( $module, @import );

    my ( $pkg, $file, $line ) = $ctx->trace()->call();

    # We need the stringy eval() so we can mess with Perl's concept of
    # what the current file and line number are for the purpose of
    # formatting the exception, AND as a convenience to get symbols
    # imported.
    eval <<"EOD"	## no critic (ProhibitStringyEval)
package $pkg;
#line $line "$file"
$use;
1;
EOD
	and return $ctx->pass_and_release( $use );

    chomp $@;	# Note that this was localized above

    return $ctx->fail_and_release( $use, $@ );
}

sub use_module_or_skip_all ($;@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $module, @import ) = @_;

    local $@ = undef;

    defined $module
	or croak MODNAME_UNDEF;

    my $use = _build_use( $module, @import );

    my ( $pkg, $file, $line );
    {
	my $lvl = 0;
	while ( ( $pkg, $file, $line ) = caller $lvl++ ) {
	    $file =~ m/ \A [(] eval \b /smx	# )
		or last;
	}
    }

    # We need the stringy eval() so we can mess with Perl's concept of
    # what the current file and line number are for the purpose of
    # formatting the exception, AND as a convenience to get symbols
    # imported.
    eval <<"EOD"	## no critic (ProhibitStringyEval)
package $pkg;
#line $line "$file"
$use;
1;
EOD
	and return;

    my $ctx = Test2::API::context();
    $ctx->plan( 0, SKIP => "Unable to $use" );
    $ctx->release();
    return;
}

sub _build_use {
    my ( $module, @import ) = @_;

    my $use;
    if ( @import && $import[0] =~ LAX_VERSION ) {
	my $version = shift @import;
	$use = "use $module $version";
    } else {
	$use = "use $module";
    }

    @import
	and $use .= " qw{ @import }";

    return $use;
}

1;

__END__

=head1 NAME

Test2::Tools::LoadModule - Test whether a module can be successfully loaded.

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Plugin::BaleOnFail;
 use Test2::Tools::LoadModule;
 
 require_module_ok( 'My::Module' );
 
 done_testing();

=head1 DESCRIPTION

This L<Test2::Tools|Test2::Tools> module provides functionality
analogous to L<Test::More|Test::More>'s C<require_ok()> and C<use_ok()>.

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
of modules. For example, I have found it necessary to load
L<Test::Builder|Test::Builder> before L<Test2::V0|Test2::V0> if I am
using C<use_module_or_skip_all()> to load
L<Test::Perl::Critic|Test::Perl::Critic> to avoid warnings.

=head1 SUBROUTINES

The following subroutines are exported by default.

=head2 require_module_ok

 require_module_ok( 'My::Module', 'Trying to load My::Module' );

This subroutine tests whether the specified module (B<not> file) can be
loaded. The test succeeds if the module can be loaded, and fails if it
can not. If L<Test2::Plugin::BailOnFail|Test2::Plugin::BailOnFail> has
been loaded, a failure causes the entire test run to be aborted. You can
achieve that effect on a per-test basis using something like

 require_module_ok( 'My::Module' )
     or bail_out( 'Unable to load My::Module' );

Note that if the test succeeds the specified module has in fact been
loaded.

This subroutine takes an optional second argument which is the name of
the test. If unspecified or specified as C<undef> or C<''>, this
defaults to C<"Require $module_name">. Subsequent optional arguments are
emitted as diagnostics if the test fails. C<$@> will be appended.

This subroutine does not support the autovivification of the module's
stash. In other words, when or whether this happens is an implementation
detail that may change without notice. See the L<require> documentation
for more information. I<Caveat coder.>

Undefined module names are trapped as a convenience to this module.
Otherwise, invalid module names are unsupported. That is, no attempt is
made to trap them, so the errors you get (if any) are totally dependent
on the underlying Perl, OS, and file system, and maybe even the phase of
the Moon.

The prototype is C<($;$@)>, so you could do, if you chose,

 require_module_ok 'My::Module';

In a context where you don't want the behavior that the prototype brings
you can always prepend C<&>, e.g.

 perl -MTest::V0 -MTest2::Tools::RequireOK \
   -e '&require_ok( @ARGV ); done_testing;' \
   My::Bogus::Module '' "We're hosed" -EE

if you are just messing around with this module.

=head2 use_module_ok

 use_module_ok( 'My::Module', ':all' );

This subroutine tests whether the given module can be loaded. Arguments
after the first represent an optional version and an import list. The
test succeeds if the module can be C<use()>-ed and the import list can
in fact be imported. If no import list is specified the default import
will be done. If you wish no import to be done the import list should
consist only of the string C<'()'>.

The import will be done into the name space that issued the call, but
B<note> that subsequent code will not see the import unless the whole
thing is called inside a C<BEGIN> block, so:

 BEGIN {
     use_module_ok( 'My::Module', ':all' );
 }
 # exported symbols can be used here, but only
 # because the call to use_module_ok() was done
 # inside a BEGIN block.

There is no way to specify a C<use> without importing. If no explicit
import list is given the default import is done.

There is also no way to specify the name of the test. The name will be,
willy-nilly, the C<use> statement actually issued.

Similarly, there is no way to specify diagnostics if the test fails.
Failure will result in a single diagnostic, which is the contents of
C<$@>.

If the first optional argument looks like a version number it will be
treated as such. The regular expression to do this was lifted from
C<$version::regex::LAX>.

The prototype is C<$;@>.

=head2 use_module_or_skip_all

 use_module_or_skip_all( 'My::Module', ':all' );

This subroutine has the same signature as
L<use_module_ok()|/use_module_ok>, but it does B<not> perform a test.
Instead it loads the given module and performs the specified import. If
the load and import succeed, it simply returns. If either fails it
issues a C<skip_all()> with the message C<'Failed to ...'>, where the
ellipsis is the actual C<use()> issued.

If the module name is C<undef>, this subroutine calls C<croak()>.

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
