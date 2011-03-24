
use strict;
use warnings;

BEGIN { require 5.12.1; }

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share module => "Yukki::Web", "skel";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'Yet Uh-nother wiki',
  'AUTHOR' => 'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Yukki',
  'EXE_FILES' => [
    'bin/yukki-add-user',
    'bin/yukki-git-init',
    'bin/yukki-setup',
    'bin/yukki.psgi'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Yukki',
  'PREREQ_PM' => {
    'Digest::SHA1' => '0',
    'File::Copy::Recursive' => '0',
    'File::Path' => '0',
    'File::ShareDir' => '0',
    'Git::Repository' => '0',
    'HTTP::Throwable::Factory' => '0',
    'IO::Prompter' => '0',
    'JSON' => '0',
    'LWP::MediaTypes' => '0',
    'List::MoreUtils' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Params::Validate' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::Path::Class' => '0',
    'MooseX::Types::Structured' => '0',
    'Number::Bytes::Human' => '0',
    'Path::Class' => '0',
    'Path::Router' => '0',
    'Path::Router::Route' => '0',
    'Path::Router::Route::Match' => '0',
    'Plack::Request' => '0',
    'Plack::Response' => '0',
    'Scalar::Util' => '0',
    'Template::Semantic' => '0',
    'Text::MultiMarkdown' => '0',
    'Throwable::Error' => '0',
    'Try::Tiny' => '0',
    'XML::Twig' => '0',
    'YAML' => '0',
    'autodie' => '0'
  },
  'VERSION' => '0.110830',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


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

package
MY;
use File::ShareDir::Install qw(postamble);


