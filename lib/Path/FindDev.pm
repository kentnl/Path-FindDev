use strict;
use warnings;

package Path::FindDev;

# ABSTRACT: Find a development path somewhere in an upper heirarchy.

=head1 DESCRIPTION

This package is mostly a glue layer around L<< C<Path::IsDev>|Path::IsDev >>
with a few directory walking tricks.

    use Path::FindDev qw( find_dev );

    if ( my $root = find_dev('/some/path/to/something/somewhere')) {
        print "development root = $root";
    } else {
        print "No development root :(";
    }

=head1 EXAMPLE USECASES

Have you ever found yourself doing

    use FindBin;
    use lib "$FindBin::Bin/../../../tlib"

In a test?

Have you found yourself paranoid of filesystem semantics and tried

    use FindBin;
    use Path::Tiny qw(path)
    use lib path($FindBin::Bin)->parent->parent->parent->child('tlib')->stringify;

Have you ever done either of the above in a test, only to
find you've needed to move the test to a deeper hierarchy,
and thus, need to re-write all your path resolution?

Have you ever had this problem for mulitple files?

No more!

    use FindBin;
    use Path::FindDev qw(find_dev);
    use lib find_dev($FindBin::Bin)->child('t','tlib')->stringify;

^ Should work, regardless of which test you put it in, and regardless
of what C<$CWD> happens to be when you call it.

=cut

use Sub::Exporter -setup => { exports => [ find_dev => \&_build_find_dev, ] };

sub _path    { require Path::Tiny; goto &Path::Tiny::path }
sub _rootdir { require File::Spec; return File::Spec->rootdir() }
sub _osroot  { _path(_rootdir)->absolute }

our $ENV_KEY_DEBUG = 'PATH_FINDDEV_DEBUG';
our $DEBUG = ( exists $ENV{$ENV_KEY_DEBUG} ? $ENV{$ENV_KEY_DEBUG} : undef );

=func C<debug>

debugging callback:

    debug('some_message') # → '[Path::FindDev] some_message\n'

To enable debug messages to C<STDERR>

    export PATH_FINDDEV_DEBUG=1

=cut

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
  flow: {
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
      redo flow;
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
    Path::IsDev->_build_is_dev( 'is_dev', $args );
  };

  return _build_find_dev_all( $class, $name, { %$arg, isdev => $isdev } );

}

*find_dev = _build_find_dev( __PACKAGE__, 'find_dev', {} );

1;
