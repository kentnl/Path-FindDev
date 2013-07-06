
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4005"
  },
  "configure_requires" => {
    "Module::Build" => "0.4005"
  },
  "dist_abstract" => "Find a development path somewhere in an upper hierarchy.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Path-FindDev",
  "dist_version" => "0.1.0",
  "license" => "perl",
  "module_name" => "Path::FindDev",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Spec" => 0,
    "Path::IsDev" => "v0.1.1",
    "Path::Tiny" => 0,
    "Sub::Exporter" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.98"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
