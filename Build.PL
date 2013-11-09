
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4008"
  },
  "configure_requires" => {
    "Module::Build" => "0.4008"
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
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.4008",
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
