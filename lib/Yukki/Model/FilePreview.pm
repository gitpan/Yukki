package Yukki::Model::FilePreview;
BEGIN {
  $Yukki::Model::FilePreview::VERSION = '0.111280';
}
use 5.12.1;
use Moose;

extends 'Yukki::Model::File';

# ABSTRACT: a sub-class of the File model for handling previews


has content => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


override fetch => sub {
    my $self = shift;
    return $self->content;
};

1;

__END__
=pod

=head1 NAME

Yukki::Model::FilePreview - a sub-class of the File model for handling previews

=head1 VERSION

version 0.111280

=head1 DESCRIPTION

This is a sub-class of L<Yukki::Model::File> that replaces the C<fetch> method with one that loads the content from a scalar attribute.

=head1 ATTRIBUTES

=head2 content

This is the content the file should have in the preview.

=head1 METHODS

=head2 fetch

Returns the value of L</content>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

