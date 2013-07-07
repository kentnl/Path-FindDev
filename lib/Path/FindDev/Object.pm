
use strict;
use warnings;

package Path::FindDev::Object;

# ABSTRACT: Object oriented guts to C<FindDev>

our $ENV_KEY_DEBUG = 'PATH_FINDDEV_DEBUG';
our $DEBUG = ( exists $ENV{$ENV_KEY_DEBUG} ? $ENV{$ENV_KEY_DEBUG} : undef );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::FindDev::Object",
    "interface":"class",
    "inherits":"Moo::Object"
}

=end MetaPOD::JSON

=cut

=head1 DESCRIPTION

This module implements the innards of L<< C<Path::FindDev>|Path::FindDev >>, and is
only recommended for use if the Exporter C<API> is insufficient for your needs.

=head1 SYNOPSIS

    require Path::FindDev::Object;
    my $finder = Path::FindDev::Object->new();
    my $dev = $finder->find_dev($path);

=cut

use Moo;

=attr C<set>

B<(optional)>

The C<Path::IsDev::HeuristicSet> subclass for your desired Heuristics.

=cut

has 'set' => ( is => ro =>, predicate => 'has_set', );

=attr C<os_root>

A Path::Tiny object for C<< File::Spec->rootdir >>

=cut

has 'os_root' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require File::Spec;
    require Path::Tiny;
    return Path::Tiny::path( File::Spec->rootdir() )->absolute;
  },
);

=attr C<uplevel_max>

If provided, limits the number of C<uplevel> iterations done.

( that is, limits the number of times it will step up the hierarchy )

=cut

has 'uplevel_max' => ( is => ro =>, lazy => 1, predicate => 'has_uplevel_max', );

=attr C<nest_retry>

The the number of C<dev> directories to C<ignore> in the hierarchy.

This is provided in the event you have a C<dev> directory within a C<dev> directory, and you wish
to resolve an outer directory instead of an inner one.

By default, this is C<0>, or "stop at the first C<dev> directory"

=cut

has 'nest_retry' => ( is => ro =>, lazy => 1, builder => sub { 0 }, );

=attr C<isdev>

The L<< C<Path::IsDev>|Path::IsDev >> object that checks nodes for C<dev>-ishness.

=cut

has 'isdev' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::IsDev::Object;
    return Path::IsDev::Object->new( ( $_[0]->has_set ? ( set => $_[0]->set ) : () ) );
  },
);

my $instances   = {};
my $instance_id = 0;

=p_method C<_instance_id>

An opportunistic sequence number for help with debug messages.

Note: This is not guaranteed to be unique per instance, only guaranteed
to be constant within the life of the object.

Based on C<refaddr>, and giving out new ids when new C<refaddr>'s are seen.

    my $id = $object->_instance_id;

=cut

sub _instance_id {
  my ($self) = @_;
  require Scalar::Util;
  my $addr = Scalar::Util::refaddr($self);
  return $instances->{$addr} if exists $instances->{$addr};
  $instances->{$addr} = sprintf '%x', $instance_id++;
  return $instances->{$addr};
}

=p_method C<BUILD>

C<BUILD> is an implementation detail of C<Moo>/C<Moose>.

This module hooks C<BUILD> to give a self report of the object
to C<*STDERR> after C<< ->new >> when under C<$DEBUG>

=cut

sub BUILD {
  my ($self) = @_;
  return $self unless $DEBUG;
  $self->_debug('{');
  $self->_debug( '  set         => ' . $self->set ) if $self->has_set;
  $self->_debug( '  os_root     => ' . $self->os_root );
  $self->_debug( '  uplevel_max => ' . $self->uplevel_max ) if $self->uplevel_max;
  $self->_debug( '  nest_retry  => ' . $self->nest_retry );
  $self->_debug( '  isdev       => ' . $self->isdev );
  $self->_debug('}');
  return $self;
}

=p_method C<_debug>

The debugger callback.

    export PATH_FINDDEV_DEBUG=1

to get debug info.

    $object->_debug($message);

=cut

sub _debug {
  my ( $self, $message ) = @_;
  return unless $DEBUG;
  my $id = $self->_instance_id;
  return *STDERR->printf( qq{[Path::FindDev=%s] %s\n}, $id, $message );
}

=p_method C<_error>

The error reporting callback.

    $object->_error($message);

=cut

sub _error {
  my ( $self, $message ) = @_;
  my $id = $self->_instance_id;
  my $f_message = sprintf qq{[Path::FindDev=%s] %s\n}, $id, $message;
  require Carp;
  Carp::croak($f_message);
}

=p_method C<_step>

Inner code path of tree walking.

    my ($dev_levels, $uplevels ) = (0,0);

    my $result = $object->_step( path($somepath), \$dev_levels, \$uplevels );

    $result->{type} eq 'stop'   # if flow control should end
    $result->{type} eq 'next'   # if flow control should ascend to parent
    $result->{type} eq 'found'  # if flow control has found the "final" dev directory


=cut

sub _step {
  my ( $self, $search_root, $dev_levels, $uplevels ) = @_;

  if ( $self->has_uplevel_max and ${$uplevels} > $self->uplevel_max ) {
    $self->_debug( 'Stopping search due to uplevels(%s) >= uplevel_max(%s)', ${$uplevels}, $self->uplevel_max );
    return { type => 'stop' };
  }
  if ( $search_root->stringify eq $self->os_root->stringify ) {
    $self->_debug('Found OS Root');
    return { type => 'stop' };
  }
  if ( $self->isdev->matches($search_root) ) {
    $self->_debug( 'Found dev dir' . $search_root );
    ${$dev_levels}++;
    return { type => 'found', path => $search_root } if ${$dev_levels} >= $self->nest_retry;
    $self->_debug( sprintf 'Ignoring found dev dir due to dev_levels(%s) < nest_retry(%s)', ${$dev_levels}, $self->nest_retry );
  }
  return { type => 'next' };
}

=method C<find_dev>

Find a parent at, or above C<$OtherPath> that resembles a C<devel> directory.

    my $path = $object->find_dev( $OtherPath );

=cut

sub find_dev {
  my ( $self, $path ) = @_;
  require Path::Tiny;
  my $search_root = Path::Tiny::path($path)->absolute;
  $self->_debug( 'Finding dev for ' . $path );
  my $dev_levels = 0;
  my $uplevels   = 0 - 1;
FLOW: {
    $uplevels++;
    my $result = $self->_step( $search_root, \$dev_levels, \$uplevels );
    if ( $result->{type} eq 'next' ) {
      $self->_debug('Trying ../');
      $search_root = $search_root->parent;
      redo FLOW;
    }
    if ( $result->{type} eq 'stop' ) {
      return;
    }
    if ( $result->{type} eq 'found' ) {
      return $result->{path};
    }
    $self->_error( 'Unexpected end of flow control with _step response type' . $result->{type} );
  }
  return;
}
1;
