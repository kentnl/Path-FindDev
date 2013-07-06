use strict;
use warnings;

package Path::FindDev;
BEGIN {
  $Path::FindDev::AUTHORITY = 'cpan:KENTNL';
}
{
  $Path::FindDev::VERSION = '0.1.0';
}

# ABSTRACT: Find a development path somewhere in an upper hierarchy.


use Sub::Exporter -setup => { exports => [ find_dev => \&_build_find_dev, ] };

sub _path    { require Path::Tiny; goto &Path::Tiny::path }
sub _rootdir { require File::Spec; return File::Spec->rootdir() }
sub _osroot  { return _path(_rootdir)->absolute }

our $ENV_KEY_DEBUG = 'PATH_FINDDEV_DEBUG';
our $DEBUG = ( exists $ENV{$ENV_KEY_DEBUG} ? $ENV{$ENV_KEY_DEBUG} : undef );


sub debug {
  return unless $DEBUG;
  return *STDERR->printf( qq{[Path::FindDev] %s\n}, shift );
}

sub _build_find_dev_all {
  my ( $class, $name, $arg ) = @_;
  my $isdev = $arg->{isdev};
  my $root  = _osroot;
  return sub {
    my ($path) = @_;
    my $path_o = _path($path)->absolute;
  FLOW: {
      debug( 'Checking :' . $path );
      if ( $path_o->stringify eq $root->stringify ) {
        debug('Found OS Root');
        return;
      }
      if ( $isdev->($path_o) ) {
        debug( 'Found dev dir ' . $path_o );
        return $path_o;
      }
      debug('Trying ../ ');
      $path_o = $path_o->parent;
      redo FLOW;
    }
    return;
  };
}

sub _build_find_dev {
  my ( $class, $name, $arg ) = @_;

  require Path::IsDev;
  my $isdev = do {
    my $args = {};
    $args->{set} = $arg->{set} if $arg->{set};
    ## no critic (ProtectPrivateSubs)
    Path::IsDev->_build_is_dev( 'is_dev', $args );
  };

  return _build_find_dev_all( $class, $name, { %{$arg}, isdev => $isdev } );

}


*find_dev = _build_find_dev( __PACKAGE__, 'find_dev', {} );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Path::FindDev - Find a development path somewhere in an upper hierarchy.

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This package is mostly a glue layer around L<< C<Path::IsDev>|Path::IsDev >>
with a few directory walking tricks.

    use Path::FindDev qw( find_dev );

    if ( my $root = find_dev('/some/path/to/something/somewhere')) {
        print "development root = $root";
    } else {
        print "No development root :(";
    }

=head1 FUNCTIONS

=head2 C<debug>

debugging callback:

    debug('some_message') # → '[Path::FindDev] some_message\n'

To enable debug messages to C<STDERR>

    export PATH_FINDDEV_DEBUG=1

=head2 find_dev

    my $result = find_dev('/some/path');

If a C<dev> directory is found at, or above, C</some/path>, it will be returned
as a L<< C<Path::Tiny>|Path::Tiny >>

If you pass configurations to import:

    use Path::FindDev find_dev => { set => $someset };

Then the exported C<find_dev> will pass that set name to L<< C<Path::IsDev>|Path::IsDev >>.

Though you should only do this if

=over 4

=item * the default set is inadequate for your usage

=item * you don't want the set to be overridden by C<%ENV>

=back

Additionally, you can call find_dev directly:

    require Path::FindDev;

    my $result = Path::FindDev::find_dev('/some/path');

Which by design inhibits your capacity to specify an alternative set in code.

=head1 EXAMPLE USE-CASES

Have you ever found yourself doing

    use FindBin;
    use lib "$FindBin::Bin/../../../tlib"

In a test?

Have you found yourself paranoid of file-system semantics and tried

    use FindBin;
    use Path::Tiny qw(path)
    use lib path($FindBin::Bin)->parent->parent->parent->child('tlib')->stringify;

Have you ever done either of the above in a test, only to
find you've needed to move the test to a deeper hierarchy,
and thus, need to re-write all your path resolution?

Have you ever had this problem for multiple files?

No more!

    use FindBin;
    use Path::FindDev qw(find_dev);
    use lib find_dev($FindBin::Bin)->child('t','tlib')->stringify;

^ Should work, regardless of which test you put it in, and regardless
of what C<$CWD> happens to be when you call it.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
