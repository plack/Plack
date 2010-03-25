package Plack::Middleware::LighttpdScriptNameFix;
use strict;
use parent qw/Plack::Middleware/;

sub call {
    my($self, $env) = @_;

    if ($env->{SERVER_SOFTWARE} && $env->{SERVER_SOFTWARE} =~ /lighttpd/) {
        $env->{PATH_INFO} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{SCRIPT_NAME} = '';
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::LighttpdScriptNameFix - fixes wrong SCRIPT_NAME and PATH_INFO that lighttpd sets

=head1 SYNOPSIS

  enable "LighttpdScriptNameFix";

=head1 DESCRIPTION

This middleware fixes wrong C<SCRIPT_NAME> and C<PATH_INFO> set by
lighttpd when you mount your app under the root path ("/"). If you use
lighttpd 1.4.23 or later you can instead enable C<fix-root-scriptname>
flag inside C<fastcgi.server> instead of using this middleware.

=head1 AUTHORS

tadam

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Handler::FCGI>
L<http://github.com/miyagawa/Plack/issues#issue/68>
L<https://redmine.lighttpd.net/issues/729>

=cut

