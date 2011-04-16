package Yukki::Web::View::Page;
BEGIN {
  $Yukki::Web::View::Page::VERSION = '0.111060';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::View';

# ABSTRACT: render HTML for viewing and editing wiki pages


sub blank {
    my ($self, $ctx, $vars) = @_;

    my $link = "/page/edit/$vars->{repository}/$vars->{page}";

    $ctx->response->page_title($vars->{title});
    $ctx->response->breadcrumb($vars->{breadcrumb});

    return $self->render_page(
        template => 'page/blank.html',
        context  => $ctx,
        vars     => {
            '#yukkiname'        => $vars->{page},
            '#create-page@href' => $link,
        },
    );
}


sub page_navigation {
    my ($self, $response, $this_action, $vars) = @_;

    for my $action (qw( view edit history )) {
        next if $action eq $this_action;

        $response->add_navigation_item({
            label => ucfirst $action,
            href  => join('/', '/page', $action, $vars->{repository}, $vars->{page}),
            sort  => undef,
        });
    }
}


sub view {
    my ($self, $ctx, $vars) = @_;

    $ctx->response->page_title($vars->{title});
    $ctx->response->breadcrumb($vars->{breadcrumb});

    my $html = $self->yukkitext({
        page       => $vars->{page},
        repository => $vars->{repository},
        yukkitext  => $vars->{content},
    });

    $self->page_navigation($ctx->response, 'view', $vars);

    return $self->render_page(
        template => 'page/view.html',
        context  => $ctx,
        vars     => {
            '#yukkitext' => \$html,
        },
    );
}


sub history {
    my ($self, $ctx, $vars) = @_;

    $ctx->response->page_title($vars->{title});
    $ctx->response->breadcrumb($vars->{breadcrumb});

    $self->page_navigation($ctx->response, 'history', $vars);

    my $i = 0;
    return $self->render_page(
        template => 'page/history.html',
        context  => $ctx,
        vars     => {
            'form@action' => join('/', '/page/diff', $vars->{repository}, $vars->{page}),
            '.revision'   => [
                map { 
                    my $r = {
                        '.first-revision input@value'  => $_->{object_id},
                        '.second-revision input@value' => $_->{object_id},
                        '.date'                        => $_->{time_ago},
                        '.author'                      => $_->{author_name},
                        '.diffstat'                    => sprintf('+%d/-%d', 
                            $_->{lines_added}, $_->{lines_removed},
                        ),
                        '.comment'                     => $_->{comment} || '(no comment)',
                    }; 

                    my $checked = sub { shift->setAttribute(checked => 'checked'); \$_ };

                    $r->{'.first-revision  input'} = $checked if $i == 1;
                    $r->{'.second-revision input'} = $checked if $i == 0;

                    $i++;

                    $r;
                } @{ $vars->{revisions} }
            ],
        },
    );
}


sub diff {
    my ($self, $ctx, $vars) = @_;

    $ctx->response->page_title($vars->{title});
    $ctx->response->breadcrumb($vars->{breadcrumb});

    $self->page_navigation($ctx->response, 'diff', $vars);

    my $diff = '';
    for my $chunk (@{ $vars->{diff} }) {
        given ($chunk->[0]) {
            when (' ') { $diff .= $chunk->[1] }
            when ('+') { $diff .= sprintf '<ins markdown="1">%s</ins>', $chunk->[1] }
            when ('-') { $diff .= sprintf '<del markdown="1">%s</del>', $chunk->[1] }
            default { warn "unknown chunk type $chunk->[0]" }
        }
    }

    my $html = $self->yukkitext({
        page       => $vars->{page},
        repository => $vars->{repository},
        yukkitext  => $diff,
    });

    return $self->render_page(
        template => 'page/diff.html',
        context  => $ctx,
        vars     => {
            '#diff' => \$html,
        },
    );
}


sub edit {
    my ($self, $ctx, $vars) = @_;

    $ctx->response->page_title($vars->{title});
    $ctx->response->breadcrumb($vars->{breadcrumb});

    my $html = $self->yukkitext({
        page       => $vars->{page},
        repository => $vars->{repository},
        yukkitext  => $vars->{content},
    });

    $self->page_navigation($ctx->response, 'edit', $vars);

    my %attachments;
    if (@{ $vars->{attachments} }) {
        %attachments = (
            '#attachments-list@class' => 'attachment-list',
            '#attachments-list'       => $self->attachments($vars->{attachments}),
        );
    }

    return $self->render_page(
        template => 'page/edit.html',
        context  => $ctx,
        vars     => {
            '#yukkiname'              => $vars->{page},
            '#yukkitext'              => $vars->{content} // '',
            '#preview-yukkitext'      => \$html,
            %attachments,
        },
    );
}


sub attachments {
    my ($self, $attachments) = @_;

    return $self->render(
        template   => 'page/attachments.html',
        vars       => {
            '.file' => [ map { +{
                './@id'     => $_->file_id,
                '.filename' => $_->file_name,
                '.size'     => $_->formatted_file_size,
                '.action'   => $self->attachment_links($_),
            } } @$attachments ],
        },
    );
}


sub attachment_links {
    my ($self, $attachment) = @_;

    my @links;

    push @links, { 
        label => 'View',
        href  => join('/', '/attachment', 'view', 
                 $attachment->repository_name, 
                 $attachment->full_path),
    } if $attachment->media_type ne 'application/octet';

    push @links, {
        label => 'Download',
        href  => join('/', '/attachment', 'download',
                 $attachment->repository_name,
                 $attachment->full_path),
    };

    return $self->render_links(links => \@links);
}


sub preview {
    my ($self, $ctx, $vars) = @_;

    my $html = $self->yukkitext({
        page       => $vars->{page},
        repository => $vars->{repository},
        yukkitext  => $vars->{content},
    });

    return $html;
}

1;

__END__
=pod

=head1 NAME

Yukki::Web::View::Page - render HTML for viewing and editing wiki pages

=head1 VERSION

version 0.111060

=head1 DESCRIPTION

Renders wiki pages.

=head1 METHODS

=head2 blank

Renders a page that links to the edit page for this location. This helps you
create the links.

=head2 page_navigation

Sets up the page navigation menu.

=head2 view

Renders a page as a view.

=head2 history

Display the history for a page.

=head2 diff

Display a diff for a file.

=head2 edit

Renders the editor for a page.

=head2 attachments

Renders the attachments table.

=head2 attachment_links

Renders the links listed in the action column of the attachments table.

=head2 preview

Renders a preview of an edit in progress.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

