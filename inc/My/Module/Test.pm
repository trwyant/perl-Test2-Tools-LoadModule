package My::Module::Test;

use 5.008001;

use strict;
use warnings;

use Carp qw{ croak };
use Exporter ();
use Test2::V0 -target => 'Test2::Tools::LoadModule';
use Test2::Util qw{ pkg_to_file };

our $VERSION = '0.000_008';

our @EXPORT_OK = qw{
    -inc
    cant_locate
    CHECK_MISSING_INFO
};

# NOTE that if there are no diagnostics, info() returns undef, not an
# empty array. I find this nowhere documented, so I am checking for
# both.
use constant CHECK_MISSING_INFO	=> in_set( undef, array{ end; } );

sub cant_locate {
    my ( $module ) = @_;
    my $fn = pkg_to_file( $module );
    return match qr<\ACan't locate $fn in \@INC\b>sm;
}

{
    # The @INC stuff is deeper magic than I like, but it lets me get rid
    # of Test::Without::Module as a testing dependency. The idea is that
    # Test2::Tools::LoadModule only sees t/lib/, but everyone else
    # can still load whatever they want. Modules already loaded at this
    # point will still appear to be loaded, no matter who requests them.
    my %special = (
	'-inc'	=> sub {
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
		};
	},
    );

    sub import {
	my ( $class, @arg ) = @_;

	@arg
	    or goto &Exporter::import;

	my @rslt;

	foreach ( @arg ) {
	    if ( my $code = $special{$_} ) {
		$code->();
	    } else {
		push @rslt, $_;
	    }
	}

	@_ = ( $class, @rslt );
	goto &Exporter::import;
    }
}

1;

__END__

=head1 NAME

My::Module::Test - Test support for Test2::Tools::LoadModule

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test qw{
     -inc
     cant_locate
     CHECK_MISSING_INFO
 };

=head1 DESCRIPTION

This module is B<private> to the C<Test2-Tools-LoadModule>
distribution. It can be changed or revoked without notice. Documentation
is for the benefit of the author only.

This module provides test support for the C<Test2-Tools-LoadModule>
distribution.

=head1 EXPORTS

This module exports nothing by default. Yes, I intend to use everything,
but there aren't many things here and if I import them explicitly it
documents what came from this module.

The following things are available for export:

=head2 -inc

This option causes a code reference to be prepended to C<@INC>. This
code reference examines the call stack, and if it finds
L<Test2::Tools::LoadModule|Test2::Tools::LoadModule> returns the
requested file from F<t/lib/>, or an error if the file is not found. If
L<Test2::Tools::LoadModule|Test2::Tools::LoadModule> is not found
on the call stack, nothing is returned, which causes Perl's normal
module-loading machinery to be invoked.

=head2 cant_locate

This subroutine takes as its argument a module name and returns a
L<Test2::V0|Test2::V0> C<match> which matches the message generated by
Perl if the module can not be located.

=head2 CHECK_MISSING_INFO

This manifest constant returns a L<Test2::V0|Test2::V0> check which
passes if the checked quantity is either C<undef> or a reference to an
empty array. This is intended to be used to check the C<info> field of
an event, since I find nowhere documented what this is if there is no
info.

=head1 SEE ALSO

L<Test2::V0|Test2::V0>

=head1 SUPPORT

This module is unsupported in the usual sense, but if you think it is
causing test failures, please file a bug report at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
