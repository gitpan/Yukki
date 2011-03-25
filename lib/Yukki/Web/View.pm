package Yukki::Web::View;
BEGIN {
  $Yukki::Web::View::VERSION = '0.110840';
}
use 5.12.1;
use Moose;

use MooseX::Params::Validate;
use Path::Class;
use Scalar::Util qw( blessed reftype );
use Template::Semantic;
use Text::MultiMarkdown;
use XML::Twig;

# ABSTRACT: base class for Yukki::Web views


has app => (
    is          => 'ro',
    isa         => 'Yukki::Web',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);


has markdown => (
    is          => 'ro',
    isa         => 'Text::MultiMarkdown',
    required    => 1,
    lazy_build  => 1,
    handles     => {
        'format_markdown' => 'markdown',
    },
);

sub _build_markdown {
    Text::MultiMarkdown->new(
        markdown_in_html_blocks => 1,
        heading_ids             => 0,
    );
}


has semantic => (
    is          => 'ro',
    isa         => 'Template::Semantic',
    required    => 1,
    lazy_build  => 1,
);

sub _build_semantic { 
    my $self = shift;

    my $semantic = Template::Semantic->new;

    # TODO Maybe nice to have?
    # $semantic->define_filter(markdown => sub { \ $self->format_markdown($_) });
    # $semantic->define_filter(yukkitext => sub { \ $self->yukkitext($_) });

    return $semantic;
}


sub render_page {
    my ($self, $template, $ctx, $vars) = validated_list(\@_,
        template   => { isa => 'Str', coerce => 1 },
        context    => { isa => 'Yukki::Web::Context' },
        vars       => { isa => 'HashRef', default => {} },
    );

    my $messages = $self->render(
        template => 'messages.html', 
        vars     => {
            '.error'   => [ map { +{ '.' => $_ } } $ctx->list_errors   ],
            '.warning' => [ map { +{ '.' => $_ } } $ctx->list_warnings ],
            '.info'    => [ map { +{ '.' => $_ } } $ctx->list_info     ],
        },
    );

    my $main_title;
    if ($ctx->response->has_page_title) {
        $main_title = 'Yukki - ' . $ctx->response->page_title;
    }
    else {
        $main_title = 'Yukki';
    }
    
    my @nav_menu = grep { 
        my $match = $self->app->router->match($_->{href});
        my $access_level_needed = $match->access_level;
        $self->check_access(
            user       => $ctx->session->{user},
            repository => $match->mapping->{repository} // '-',
            needs      => $access_level_needed,
        );
    } $ctx->response->navigation_menu;

    return $self->render(
        template   => 'shell.html',
        vars       => {
            '#messages'   => $messages,
            '.main-title' => $main_title,
            '#navigation .navigation' => [ map { 
                { 'a' => $_->{label}, 'a@href' => $_->{href} },
            } @nav_menu ],
            '#bottom-navigation .navigation' => [ map { 
                { 'a' => $_->{label}, 'a@href' => $_->{href} },
            } @nav_menu ],
            '#breadcrumb li' => [ map {
                { 'a' => $_->{label}, 'a@href' => $_->{href} },
            } $ctx->response->breadcrumb_links ],
            '#content'    => $self->render(template => $template, vars => $vars),
        },
    )->{dom}->toStringHTML;
}


sub render_links {
    my ($self, $links) = validated_list(\@_,
        links    => { isa => 'ArrayRef[HashRef]' },
    );

    return $self->render(
        template => 'links.html',
        vars     => {
            'li' => [ map {
                { 'a' => $_->{label}, 'a@href' => $_->{href} },
            } @$links ],
        },        
    );
}


sub render {
    my ($self, $template, $vars) = validated_list(\@_,
        template   => { isa => 'Str', coerce => 1 },
        vars       => { isa => 'HashRef', default => {} },
    );
    
    my $template_file = $self->locate('template_path', $template);
    
    return $self->semantic->process($template_file, $vars);
}


sub yukkilink {
    my ($self, $params) = @_;

    my $repository = $params->{repository};
    my $link       = $params->{link};
    my $label      = $params->{label};

    my ($repo_name, $local_link) = split /:/, $link, 2 if $link =~ /:/;
    if (defined $repo_name and defined $self->app->settings->{repositories}{$repo_name}) {
        $repository = $repo_name;
        $link       = $local_link;
    }
    
    # If we did not get a label, make the label into the link
    if (not defined $label) {
        ($label) = $link =~ m{([^/]+)$};

        $link =~ s{[^a-zA-Z0-9-_./]+}{-}g;
        $link =~ s{-+}{-}g;
        $link =~ s{^-}{};
        $link =~ s{-$}{};

        $link .= '.yukki';
    }

    my @base_name;
    if ($params->{page}) {
        $base_name[0] = $params->{page};
        $base_name[0] =~ s/\.yukki$//g;
    }

    $link = join '/', @base_name, $link if $link =~ m{^\./};
    $link =~ s{^/}{};

    $label =~ s/^\s*//; $label =~ s/\s*$//;
    return qq{<a href="/page/view/$repository/$link">$label</a>};
}


sub yukkiplugin {
    my ($self, $params) = @_;

    my $plugin_name = $params->{plugin_name};
    my $arg         = $params->{arg};

    # TODO Not very pluggable yet
    return "{{$plugin_name:$arg}}" unless $plugin_name eq 'attachment';

    if ($arg =~ m{

            ^\s*

                (?: ([\w]+) : )?    # repository: is optional
                ([\w/.\-]+)         # link/to/page is mandatory

            \s*$

            }x) {

        my $repository = $1 // $params->{repository};
        my $page       = $params->{page};
        my $link       = $2;

        $page =~ s{\.yukki$}{};

        if ($link =~ m{^/}) {
            return "/attachment/view/$repository$link";
        }
        else {
            return "/attachment/view/$repository/$page/$link";
        }
    }
    
    return "{{$plugin_name:$arg}}";
}


sub yukkitext {
    my ($self, $params) = @_;

    my $repository = $params->{repository};
    my $yukkitext  = $params->{yukkitext};

    # Yukki Links
    $yukkitext =~ s{ 
        (?<!\\)                 # \ will escape the link
        \[\[ \s*                # [[ to start it

            (?: ([\w]+) : )?    # repository: is optional
            ([^|\]]+) \s*       # link/to/page is mandatory

            (?: \|              # | to split link from label
                ([^\]]+)        # a pretty label (needs trimming)
            )?                  # is optional

        \]\]                    # ]] to end
    }{ 
        $self->yukkilink({ 
            %$params, 
            
            repository => $1 // $repository, 
            link       => $2, 
            label      => $3,
        });
    }xeg;

    # Handle escaped links, hide the escape
    $yukkitext =~ s{ 
        \\                      # \ will escape the link
        (\[\[ \s*               # [[ to start it

            (?: [\w]+ : )?      # repository: is optional
            [\w/.\-]+ \s*       # link/to/page is mandatory

            (?: \|              # | to split link from label
                [^\]]+          # a pretty label (needs trimming)
            )?                  # is optional

        \]\])                    # ]] to end
    }{$1}gx;

    # Yukki Plugins
    $yukkitext =~ s{
        (?<!\\)                 # \ will escape the plugin
        \{\{ \s*                # {{ to start it

            ([\w]+) :           # plugin_name: is required

            (.*)                # plugin arguments

        \}\}                    # }} to end
    }{
        $self->yukkiplugin({
            %$params,

            plugin_name => $1,
            arg         => $2,
        });
    }xeg;

    # Handle the escaped plugin thing
    $yukkitext =~ s{
        \\                      # \ will escape the plugin
        (\{\{ \s*               # {{ to start it

            [\w]+ :             # plugin_name: is required

            .*                  # plugin arguments

        \}\})                   # }} to end
    }{$1}xg;

    return '<div>' . $self->format_markdown($yukkitext) . '</div>';
}

1;

__END__
=pod

=head1 NAME

Yukki::Web::View - base class for Yukki::Web views

=head1 VERSION

version 0.110840

=head1 DESCRIPTION

This is the base class for all L<Yukki::Web> views.

=head1 ATTRIBUTES

=head2 app

This is the L<Yukki::Web> singleton.

=head2 markdown

This is the L<Text::MultiMarkdown> object for rendering L</yukkitext>. Do not
use.

Provides a C<format_markdown> method delegated to C<markdown>. Do not use.

=head2 semantic

This is the L<Template::Semantic> object that transforms the templates. Do not use.

=head1 METHODS

=head2 render_page

  my $document = $self->render_page({
      template => 'foo.html',
      context  => $ctx,
      vars     => { ... },
  });

This renders the given template and places it into the content section of the
F<shell.html> template.

The C<context> is used to render parts of the shell template.

The C<vars> are processed against the given template with L<Template::Semantic>.

=head2 render_links

  my $document = $self->render_links(\@navigation_links);

This renders a set of links using the F<links.html> template.

=head2 render

  my $document = $self->render({
      template => 'foo.html',
      vars     => { ... },
  });

This renders the named template using L<Template::Semantic>. The C<vars> are
used as the ones passed to the C<process> method.

=head2 yukkilink

Used to help render yukkilinks. Do not use.

=head2 yukkiplugin

Used to render plugged in markup. Do not use.

=head2 yukkitext

  my $html = $view->yukkitext({
      repository => $repository_name,
      yukkitext  => $yukkitext,
  });

Yukkitext is markdown plus some extra stuff. The extra stuff is:

  [[ main:/link/to/page.yukki | Link Title ]] - wiki link
  [[ /link/to/page.yukki | Link Title ]]      - wiki link
  [[ /link/to/page.yukki ]]                   - wiki link

  {{attachment:file.pdf}}                     - attachment URL

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

