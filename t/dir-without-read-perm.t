#! /usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Path::FindDev qw(find_dev);

mkdir 'foo', 0311 or die "Failed creating foo: $!\n";
mkdir 'foo/bar' or die "Failed creating foo/bar: $!\n";

lives_ok(sub {find_dev('foo/bar')}, 'find_dev returns when called in subdir of dir without read permissions');

rmdir 'foo/bar' or die "Failed removing foo/bar: $!\n";
rmdir 'foo' or die "Failed removing foo: $!\n";

done_testing;
