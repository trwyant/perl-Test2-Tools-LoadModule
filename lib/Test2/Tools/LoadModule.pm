package Test2::Tools::LoadModule;

use 5.008001;

use strict;
use warnings;

use Carp;
use Exporter ();
use Getopt::Long 2.34;	# Comes with Perl 5.8.1.
use Test2::API ();
use Test2::Util ();

use version 0.86 qw{ is_lax };	# for is_lax()

our $VERSION = '0.000_006';

our @EXPORT =	## no critic (ProhibitAutomaticExportation)
qw{
    load_module_ok
    load_module_or_skip_all
};

our @EXPORT_OK = ( @EXPORT, qw{
    __build_load_eval
    __perl_import_semantics
} );

our %EXPORT_TAGS = (
    all		=> \@EXPORT,
    private	=> [ grep { m/ \A _ /smx } @EXPORT_OK ],
);

use constant ARRAY_REF		=> ref [];
use constant MODNAME_UNDEF	=> 'Module name must be defined';


sub load_module_ok ($;$$$$) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $module, $version, $import, $name, $diag ) = _validate_args( @_ );

    local $@ = undef;

    my $eval = __build_load_eval( $module, $version, $import );

    defined $name
	or $name = $eval;

    my $ctx = Test2::API::context();

    _eval_in_pkg( $eval, $ctx->trace()->call() )
	and return $ctx->pass_and_release( $name );

    chomp $@;

    return $ctx->fail_and_release( $name, @{ $diag }, $@ );
}


sub load_module_or_skip_all ($;$$$) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $module, $version, $import, $name ) = _validate_args( @_ );

    local $@ = undef;

    my $eval = __build_load_eval( $module, $version, $import );

    defined $name
	or $name = sprintf 'Unable to %s', $eval;

    _eval_in_pkg( $eval, _get_call_info() )
	and return;

    my $ctx = Test2::API::context();
    $ctx->plan( 0, SKIP => $name );
    $ctx->release();
    return;
}

{
    my $key = sprintf '%s/use_perl_import_semantics', __PACKAGE__;

    my $psr;
    # Because we want to work with Perl 5.8.1 we are limited to
    # Getopt::Long 2.34, and therefore getoptions(). So we expect the
    # arguments to be in a suitably-localized @ARGV, and we will just
    # return the options hash, so we expect no arguments.
    sub _parse_import_opts {
	my %opt;
	$psr ||= Getopt::Long::Parser->new();
	$psr->getoptions( \%opt, qw{
	    perl_import_semantics|perl-import-semantics! } )
	    or croak "Invalid import option";
	return \%opt;
    }

    sub import {	## no critic (RequireArgUnpacking,ProhibitBuiltinHomonyms)
	local @ARGV = @_;	# See _parse_import_opts
	my $opt = _parse_import_opts();
        defined $opt->{perl_import_semantics}
	    and $^H{$key} = $opt->{perl_import_semantics};
	@_ = @ARGV;
	goto &Exporter::import;
    }

    sub unimport : method {	## no critic (ProhibitBuiltinHomonyms)
	local @ARGV = @_;	# See _parse_import_opts
	my $opt = _parse_import_opts();
        defined $opt->{perl_import_semantics}
	    and $^H{$key} = ( ! $opt->{perl_import_semantics} );
        return;	# There is no Exporter::unimport
    }

    sub __perl_import_semantics {
	my ( $level ) = @_;
	my $hint_hash = ( caller( $level || 0 ) )[ 10 ];
	return $hint_hash->{$key} || 0;
    }
}

sub __build_load_eval {
    my ( $module, $version, $import ) = @_;
    my @eval = "use $module";

    defined $version
	and push @eval, $version;

    if ( $import && @{ $import } ) {
	push @eval, "qw{ @{ $import } }";
    } elsif ( __perl_import_semantics( 1 ) xor defined $import ) {
    } else {
	push @eval, '()';
    }

    return "@eval";
}


sub _validate_args {
    my ( $module, $version, $import, $name, $diag ) = @_;

    defined $module
	or croak MODNAME_UNDEF;

    if ( defined $version ) {
	is_lax( $version )
	    or croak "Version '$version' is invalid";
    }

    not defined $import
	or ARRAY_REF eq ref $import
	or croak 'Import list must be an array reference, or undef';

    defined $diag
	or $diag = [];
    ARRAY_REF eq ref $diag
	or croak 'Diagnostics must be an array reference, or undef';

    return ( $module, $version, $import, $name, $diag );
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
    # IM(NS)HO the RequireCheckingReturnValueOfEval annotation
    # represents a bug in
    # Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval
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
 use Test2::Plugin::BaleOnFail;
 use Test2::Tools::LoadModule;
 
 load_module_ok( 'My::Module' );
 
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
of modules. I ran into this in the early phases of implementation, and
fixed it for my own use by initializing the testing system as late as
possible, but I can not promise that all such problems have been
eliminated.

=head1 SUBROUTINES

The following subroutines are exported by default.

=head2 load_module_ok

 load_module_ok( $module, $ver, $import, $name, $diag );

This subroutine tests whether the specified module (B<not> file) can be
loaded. All arguments are optional but the first. The arguments are:

=over

=item $module - the module name

This is required, and must not be C<undef>.

=item $ver - the desired version number, or undef

If defined, it must be a valid version, and a version check is done.

If C<undef>, no version check is done.

=item $import - the import list as an array ref, or undef

By default, C<undef> means do not import, an empty array means do the
default import. See L<IMPORT SEMANTICS|/IMPORT SEMANTICS>, below, for
details.

=item $name - the test name, or undef

If C<undef>, the name defaults to the code used to load the module.
B<Note> that this code, and therefore the default name, may change
without notice.

=item $diag - the desired diagnostics as an array ref, or undef

If C<undef>, an empty array is used. Diagnostics are only issued on
failure.

=back

Argument validation failures are signalled by C<croak()>.

The module is loaded using the C<require> built-in, and version checks
and imports are done if specified. The test passes if all these
succeeds, and fail otherwise. In the event of failure, C<$@> is appended
to the diagnostics.

B<Note> that any imports take place when this subroutine is called,
which is normally at run time. Imported subroutines will be callable,
provided you do not make use of prototypes or attributes.

If you want anything imported from the loaded module to be available for
subsequent compilation (e.g. variables, subroutine prototypes) you will
need to put the call to this subroutine in a C<BEGIN { }> block:

 BEGIN { load_module_ok( 'My::Module' ) }

=head2 load_module_or_skip_all

 load_module_or_skip_all( $module, $ver, $import, $name );

The arguments are the same as L<load_module_ok()|/load_module_ok>,
except for the fact that diagnostics are not specified. The module is
loaded in the same way, but no tests are performed. Instead, if the load
fails for any reason, all tests are skipped. The C<$name> argument gives
the reason to skip, and defaults to C<"Unable to ..."> where the
ellipsis is the code used to load the module.

This subroutine can be called either at the top level or in a subtest,
but either way it B<must> be called before any actual tests in the file
or subtest.

=head1 IMPORT SEMANTICS

By default, the semantics of this module's C<$import> argument are not
those of the Perl C<use()> built-in. Specifically, C<undef> or missing
cause the module's C<import()> not to be called at all, whereas an array
reference causes C<import()> to be called and passed the contents of the
array, if any.

These semantics seemed to the author more natural when testing -- that
is, when calling L<load_module_ok()|/load_module_ok>, But when calling
L<load_module_or_skip_all()|/load_module_or_skip_all>, the Perl C<use()>
semantics seemed more natural. That is, an unspecified or C<undef>
C<$import> causes the default import, but C<[]> causes C<import()> not
to be called at all.

In an effort to have it both ways, this module allows you to specify

 use Test2::Tools::LoadModule '-perl-import-semantics';

to get the Perl C<use()> semantics. These take effect within the lexical
scope of the statement, so that, for example, you could issue the C<use>
at the top of a block, and drop back to the old semantics after the end
of the block. You can also go back to non-Perl semantics with an
explicit

 no Test2::Tools::LoadModule '-perl-import-semantics';

As a sample use of this,

 BEGIN {
 
     use Test2::Tools::LoadModule '-perl-import-semantics';
 
     load_module_or_skip_all 'Optional::Module';
 
     # If we don't skip all, the default import for Optional::Module
     # has been done.
 }
 # Anything exported by Optional::Module is available here, but we're
 # back to the old, non-Perl import semantics.
 
 load_module 'My::Module';  # import() not even called.

Yes, the idea of just having L<load_module_ok()|/load_module_ok> and
L<load_module_or_skip_all()|/load_module_or_skip_all> have different
import semantics was considered. It was rejected because the
inconsistency seemed like a trap for the unwary, and because it did not
provide the flexibility that the current implementation does.

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
