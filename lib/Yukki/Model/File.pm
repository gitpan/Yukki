package Yukki::Model::File;
BEGIN {
  $Yukki::Model::File::VERSION = '0.110850';
}
use 5.12.1;
use Moose;

extends 'Yukki::Model';

use Digest::SHA1 qw( sha1_hex );
use Number::Bytes::Human qw( format_bytes );
use LWP::MediaTypes qw( guess_media_type );
use Path::Class;

# ABSTRACT: the model for loading and saving files in the wiki


has path => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);


has filetype => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    required   => 1,
    default    => 'yukki',
);


has repository => (
    is         => 'ro',
    isa        => 'Yukki::Model::Repository',
    required   => 1,
    handles    => {
        'make_blob'           => 'make_blob',
        'make_blob_from_file' => 'make_blob_from_file',
        'find_root'           => 'find_root',
        'branch '             => 'branch',
        'show'                => 'show',
        'make_tree'           => 'make_tree',
        'commit_tree'         => 'commit_tree',
        'update_root'         => 'update_root',
        'find_path'           => 'find_path',
        'list_files'          => 'list_files',
        'fetch_size'          => 'fetch_size',
        'repository_name'     => 'name',
        'author_name'         => 'author_name',
        'author_email'        => 'author_email',
    },
);


sub BUILDARGS {
    my $class = shift;

    my %args;
    if (@_ == 1) { %args = %{ $_[0] }; }
    else         { %args = @_; }

    if ($args{full_path}) {
        my $full_path = delete $args{full_path};

        my ($path, $filetype) = $full_path =~ m{^(.*)(?:\.(\w+))?$};

        $args{path}     = $path;
        $args{filetype} = $filetype;
    }

    return \%args;
}


sub full_path {
    my $self = shift;

    my $full_path;
    given ($self->filetype) {
        when (defined) { $full_path = join '.', $self->path, $self->filetype }
        default        { $full_path = $self->path }
    }

    return $full_path;
}


sub file_name {
    my $self = shift;
    my $full_path = $self->full_path;
    my ($file_name) = $full_path =~ m{([^/]+)$};
    return $file_name;
}


sub file_id {
    my $self = shift;
    return sha1_hex($self->file_name);
}


sub object_id {
    my $self = shift;
    return $self->find_path($self->full_path);
}


sub title {
    my $self = shift;

    if ($self->filetype eq 'yukki') {
        LINE: for my $line ($self->fetch) {
            if ($line =~ /:/) {
                my ($name, $value) = split m{\s*:\s*}, $line, 2;
                return $value if lc($name) eq 'title';
            }
            elsif ($line =~ /^#\s*(.*)$/) {
                return $1;
            }
            else {
                last LINE;
            }
        }
    }

    my $title = $self->file_name;
    $title =~ s/\.(\w+)$//g;
    return $title;
}


sub file_size {
    my $self = shift;
    return $self->fetch_size($self->full_path);
}


sub formatted_file_size {
    my $self = shift;
    return format_bytes($self->file_size);
}


sub media_type {
    my $self = shift;
    return guess_media_type($self->full_path);
}


sub store {
    my ($self, $params) = @_;
    my $path = $self->full_path;

    my (@parts) = split m{/}, $path;
    my $blob_name = $parts[-1];

    my $object_id;
    if ($params->{content}) {
        $object_id = $self->make_blob($blob_name, $params->{content});
    }
    elsif ($params->{filename}) {
        $object_id = $self->make_blob_from_file($blob_name, $params->{filename});
    }
    Yukki::Error->throw("unable to create blob for $path") unless $object_id;

    my $old_tree_id = $self->find_root;
    Yukki::Error->throw("unable to locate original tree ID for ".$self->branch)
        unless $old_tree_id;

    my $new_tree_id = $self->make_tree($old_tree_id, \@parts, $object_id);
    Yukki::Error->throw("unable to create the new tree containing $path\n")
        unless $new_tree_id;

    my $commit_id = $self->commit_tree($old_tree_id, $new_tree_id, $params->{comment});
    Yukki::Error->throw("unable to commit the new tree containing $path\n")
        unless $commit_id;

    $self->update_root($old_tree_id, $commit_id);
}


sub exists {
    my $self = shift;

    my $path = $self->full_path;
    return $self->find_path($path);
}


sub fetch {
    my $self = shift;

    my $path = $self->full_path;
    my $object_id = $self->find_path($path);

    return unless defined $object_id;

    return $self->show($object_id);
}

1;

__END__
=pod

=head1 NAME

Yukki::Model::File - the model for loading and saving files in the wiki

=head1 VERSION

version 0.110850

=head1 SYNOPSIS

  my $repository = $app->model('Repository', { repository => 'main' });
  my $file = $repository->file({
      path     => 'foobar',
      filetype => 'yukki',
  });

=head1 DESCRIPTION

Tools for fetching files from the git repository and storing them there.

=head1 EXTENDS

L<Yukki::Model>

=head1 ATTRIBUTES

=head2 path

This is the path to the file in the repository, but without the file suffix.

=head2 filetype

The suffix of the file. Defaults to "yukki".

=head2 repository

This is the the L<Yukki::Model::Repository> the file will be fetched from or
stored into.

=head1 METHODS

=head2 BUILDARGS

Allows C<full_path> to be given instead of C<path> and C<filetype>.

=head2 full_path

This is the complete path to the file in the repository with the L</filetype>
tacked onto the end.

=head2 file_name

This is the base name of the file.

=head2 file_id

This is a SHA-1 of the file name in hex.

=head2 object_id

This is the git object ID of the file blob.

=head2 title

This is the title for the file. For most files this is the file name. For files with the "yukki" L</filetype>, the title metadata or first heading found in the file is used.

=head2 file_size

This is the size of the file in bytes.

=head2 formatted_file_size

This returns a human-readable version of the file size.

=head2 media_type

This is the MIME type detected for the file.

=head2 store

  $file->store({ 
      content => 'text to put in file...', 
      comment => 'comment describing the change',
  });

  # OR
  
  $file->store({
      filename => 'file.pdf',
      comment  => 'comment describing the change',
  });

This stores a new version of the file, either from the given content string or a
named local file.

=head2 exists

Returns true if the file exists in the repository already.

=head2 fetch

  my $content = $self->fetch;
  my @lines   = $self->fetch;

Returns the contents of the file.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
