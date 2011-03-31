package Yukki::Web::Settings;
BEGIN {
  $Yukki::Web::Settings::VERSION = '0.110900';
}
use 5.12.1;
use Moose;

extends 'Yukki::Settings';

# ABSTRACT: provides structure and validation to web settings in yukki.conf


has template_path => (
    is          => 'ro',
    isa         => 'Path::Class::Dir',
    required    => 1,
    coerce      => 1,
    default     => 'root/template',
);


has static_path => (
    is          => 'ro',
    isa         => 'Path::Class::Dir',
    required    => 1,
    coerce      => 1,
    default     => 'root',
);

1;

__END__
=pod

=head1 NAME

Yukki::Web::Settings - provides structure and validation to web settings in yukki.conf

=head1 VERSION

version 0.110900

=head1 DESCRIPTION

L<Yukki::Web> needs a few additional settings.

=head1 ATTRIBUTES

=head2 template_path

THis is the folder where Yukki will find templates under the C<root>. The default is F<root/template>.

=head2 static_path

This is the folder where Yukki will find the static files to serve for your application.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

