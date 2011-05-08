package Yukki::Web::Settings;
BEGIN {
  $Yukki::Web::Settings::VERSION = '0.111280';
}
use 5.12.1;
use Moose;

extends 'Yukki::Settings';

use Yukki::Types qw( BaseURL PluginConfig );

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


has base_url => (
    is          => 'ro',
    isa         => BaseURL,
    required    => 1,
    coerce      => 1,
    default     => 'SCRIPT_NAME',
);


has scripts => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub { 
        [ qw(
            script/lib/jquery/jquery.js
            script/lib/jquery/jquery-ui.js
            script/lib/plupload/plupload.full.js
            script/lib/sha1/sha1.js
            script/yukki.js
        ) ]
    },
    traits      => [ 'Array' ],
    handles     => {
        all_scripts => 'elements',
    },
);

has styles => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub { 
        [ qw(
            style/yukki.css
            style/lib/jquery/jquery.css
        ) ]
    },
    traits      => [ 'Array' ],
    handles     => {
        all_styles => 'elements',
    },
);


has plugins => (
    is          => 'ro',
    isa         => PluginConfig,
    required    => 1,
    default     => sub { [
        { module => 'Attachment' },
        { module => 'YukkiText' },
    ] },
);


has media_types => (
    is          => 'ro',
    isa         => 'HashRef[Str|ArrayRef[Str]]',
    required    => 1,
    default     => sub { +{
        'text/yukki' => 'yukki',
    } },
);

1;

__END__
=pod

=head1 NAME

Yukki::Web::Settings - provides structure and validation to web settings in yukki.conf

=head1 VERSION

version 0.111280

=head1 DESCRIPTION

L<Yukki::Web> needs a few additional settings.

=head1 ATTRIBUTES

=head2 template_path

THis is the folder where Yukki will find templates under the C<root>. The default is F<root/template>.

=head2 static_path

This is the folder where Yukki will find the static files to serve for your application.

=head2 base_url

This configures the L<Yukki::Web::Context/base_url> attribute. It is either an absolute URL or the words C<SCRIPT_NAME> or C<REWRITE>. See L<Yukki::Web::Context/base_url> for more information.

The default is C<SCRIPT_NAME>.

=head2 scripts

=head2 styles

This is a list of the JavaScript and CSS files, respectively, to load into the
shell template. If not set, the defaults are:

  scripts:
      - script/lib/jquery/jquery.js
      - script/lib/jquery/jquery-ui.js
      - script/lib/plupload/plupload.full.js
      - script/lib/sha1/sha1.js
      - script/yukki.js

  styles:
      - style/yukki.css
      - style/lib/jquery/jquery.css

As you can see, these are full paths and may be given as paths to foreign hosts.
In order to keep Yukki working in good order, you will probaby want to include
at least the scripts listed above.

=head2 plugins

This is the list of plugins to use. This is an array of hashes. The hashes must have a C<module> key naming the class defining the plugin. The rest of the keys will be passed to the plugin constructor.

=head2 media_types

This is a list of custom media types. Because media types are detected using L<LWP::MediaTypes>, you may also configured media types by putting a F<.media.types> file in the home directory of the user running Yukki.

By default, "text/yukki" is mapped to the "yukki" file extension.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
