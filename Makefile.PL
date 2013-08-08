
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "update your Subversion repository after release",
  "AUTHOR" => "Mark Gardner <mjgardner\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Subversion",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::Subversion",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Dist::Zilla" => "4.101550",
    "Dist::Zilla::Role::AfterRelease" => "4.101550",
    "Dist::Zilla::Role::Plugin" => "4.101550",
    "Dist::Zilla::Role::Releaser" => "4.10155",
    "English" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Types::URI" => 0,
    "Path::Class" => 0,
    "Readonly" => 0,
    "Regexp::DefaultFlags" => 0,
    "SVN::Client" => 0,
    "SVN::Wc" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "utf8" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Carp" => 0,
    "Dist::Zilla::Plugin::Repository" => 0,
    "Dist::Zilla::Tester" => "4.101550",
    "File::Temp" => 0,
    "SVN::Repos" => 0,
    "Scalar::Util" => 0,
    "Test::Moose" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Text::Template" => 0,
    "blib" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.101591",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


<<<<<<< HEAD
unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

=======
>>>>>>> 8fddaff4935e9d00da73fb24fce4ef077f643952
unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



