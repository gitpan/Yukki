package Yukki::Error;
BEGIN {
  $Yukki::Error::VERSION = '0.110900';
}
use Moose;

extends 'Throwable::Error';

# ABSTRACT: Yukki's exception class


1;

__END__
=pod

=head1 NAME

Yukki::Error - Yukki's exception class

=head1 VERSION

version 0.110900

=head1 SYNOPSIS

  Yukki::Error->throw("Something really bad.");

=head1 DESCRIPTION

If you look at L<Throwable::Error>, you know what this is. Same thing, different
name.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

