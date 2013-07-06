
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

done_testing;

