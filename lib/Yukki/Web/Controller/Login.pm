package Yukki::Web::Controller::Login;
BEGIN {
  $Yukki::Web::Controller::Login::VERSION = '0.110840';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::Controller';

use HTTP::Throwable::Factory qw( http_throw );

# ABSTRACT: shows the login page and handles login


sub fire {
    my ($self, $ctx) = @_;

    my $res;
    given ($ctx->request->path_parameters->{action}) {
        when ('page')   { $self->show_login_page($ctx) }
        when ('submit') { $self->check_login_submission($ctx) }
        when ('exit')   { $self->logout($ctx) }
        default         { http_throw('NotFound') }
    }
}


sub show_login_page {
    my ($self, $ctx) = @_;

    $ctx->response->body( $self->view('Login')->page($ctx) );
}


sub check_login_submission {
    my ($self, $ctx) = @_;
    
    my $login_name = $ctx->request->body_parameters->{login_name};
    my $password   = $ctx->request->body_parameters->{password};

    my $user = $self->model('User')->find(login_name => $login_name);

    $ctx->add_errors('no such user or you typed your password incorrectly') unless $user;

    if ($user and $user->{password} ne $password) {
        $ctx->add_errors('no such user or you typed your password incorrectly');
    }

    if ($ctx->has_errors) {
        $self->show_login_page($ctx);
        return;
    }

    else {
        $ctx->session->{user} = $user;

        $ctx->response->redirect('/page/view/main');
        return;
    }
}


sub logout {
    my ($self, $ctx) = @_;

    $ctx->session_options->{expire} = 1;
    $ctx->response->redirect('/page/view/main');
}

1;

__END__
=pod

=head1 NAME

Yukki::Web::Controller::Login - shows the login page and handles login

=head1 VERSION

version 0.110840

=head1 DESCRIPTION

Shows the login page and handles login.

=head1 METHODS

=head2 fire

Routes page reqquests to L</show_login_page>, submit requests to L</check_login_submission>, and exit requests to L</logout>.

=head2 show_login_page

Calls L<Yukki::Web::View::Login/page> to display the login page.

=head2 check_login_submission

Authenticates a user login.

=head2 logout

Expires the session, causing logout.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

