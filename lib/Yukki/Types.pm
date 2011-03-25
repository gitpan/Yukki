package Yukki::Types;
BEGIN {
  $Yukki::Types::VERSION = '0.110840';
}
use Moose;

use MooseX::Types -declare => [ qw(
    LoginName AccessLevel NavigationLinks
    BreadcrumbLinks
) ];

use MooseX::Types::Moose qw( Str Int ArrayRef Maybe );
use MooseX::Types::Structured qw( Dict );

# ABSTRACT: standard types for use in Yukki


subtype LoginName,
    as Str,
    where { /^[a-z0-9]+$/ },
    message { "login name $_ must only contain letters and numbers" };


enum AccessLevel, qw( read write none );


subtype NavigationLinks,
    as ArrayRef[
        Dict[
            label => Str,
            href  => Str,
            sort  => Maybe[Int],
        ],
    ];


subtype BreadcrumbLinks,
    as ArrayRef[
        Dict[
            label => Str,
            href  => Str,
        ],
    ];

1;

__END__
=pod

=head1 NAME

Yukki::Types - standard types for use in Yukki

=head1 VERSION

version 0.110840

=head1 SYNOPSIS

  use Yukki::Types qw( LoginName AccessLevel );

  has login_name => ( isa => LoginName );
  has access_level => ( isa => AccessLevel );

=head1 DESCRIPTION

A standard type library for Yukki.

=head1 TYPES

=head2 LoginName

This is a valid login name. Login names may only contain letters and numbers, as of this writing.

=head2 AccessLevel

This is a valid access level. This includes any of the following values:

  read
  write
  none

=head2 NavigationLinks

THis is an array of hashes formatted like:

  {
      label => 'Label',
      href  => '/link/to/somewhere',
      sort  => 40,
  }

=head2 BreadcrumbLinks

THis is an array of hashes formatted like:

  {
      label => 'Label',
      href  => '/link/to/somewhere',
  }

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

