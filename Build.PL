
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4007"
  },
  "configure_requires" => {
    "Module::Build" => "0.4007"
  },
  "dist_abstract" => "Find a development path somewhere in an upper hierarchy.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Path-FindDev",
  "dist_version" => "0.4.2",
  "license" => "perl",
  "module_name" => "Path::FindDev",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::Tiny" => "0.010",
    "Path::IsDev" => "v0.2.2",
    "Path::IsDev::Object" => 0,
    "Path::Tiny" => "0.038",
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "FindBin" => 0,
    "Test::More" => "0.99",
    "blib" => 0
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "FindBin" => 0,
  "Module::Build" => "0.4007",
  "Test::More" => "0.99",
  "blib" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
