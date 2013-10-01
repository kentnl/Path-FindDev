
use strict;
use warnings;

use Test::More;
use FindBin;

use Path::FindDev qw(find_dev);
use Path::Tiny qw(path);

sub cmp_paths {
  my ( $search, $real ) = @_;
  my $searched = find_dev($search);
  return unless ok( $searched, 'find_dev returned something' );
  $searched = $searched->absolute->stringify;
  my $realed = path($real)->absolute->stringify;
  is( $searched, $realed, 'found and expected match' );
}
cmp_paths( $FindBin::Bin, path($FindBin::Bin)->parent );

my $t_dir = path($FindBin::Bin);

my $source_root = $t_dir->parent;

my $outside_path = $source_root->parent; # PROJECT_ROOT/../

if ( $outside_path->basename eq '.build' ) {
    $outside_path = $outside_path->parent->parent;
}

diag "External search started at " . $outside_path;

if (
  not is( find_dev( $outside_path ), undef,
    'Finding a dev directory above the project directory should miss' ) )
{
  no warnings 'once';
  local $Path::IsDev::Object::DEBUG   = 1;
  local $Path::FindDev::Object::DEBUG = 1;
  diag "As the previous test failed, debug diagnosics for Path::IsDev are being turned on";
  diag "These will hopefully tell you what warts your filesystem has that results in false-postives for dev dirs";

  find_dev( $outside_path );
}
done_testing;

