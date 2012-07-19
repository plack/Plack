package Plack::Middleware::LighttpdScriptNameFix;
use strict;
use parent qw/Plack::Middleware/;
use Plack::Util::Accessor qw(script_name);

sub prepare_app {
    my $self = shift;

    my $script_name = $self->script_name;
    $script_name = '' unless defined($script_name);
    $script_name =~ s!/$!!;
    $self->script_name($script_name);
}

sub call {
    my($self, $env) = @_;

    if ($env->{SERVER_SOFTWARE} && $env->{SERVER_SOFTWARE} =~ /lighttpd/) {
        $env->{PATH_INFO}   = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{SCRIPT_NAME} = $self->script_name;
        $env->{PATH_INFO}  =~ s/^\Q$env->{SCRIPT_NAME}\E//;
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::LighttpdScriptNameFix - fixes wrong SCRIPT_NAME and PATH_INFO that lighttpd sets

=head1 SYNOPSIS

  # in your app.psgi
  use Plack::Builder;

  builder {
    enable "LighttpdScriptNameFix";
    $app;
  };

  # Or from the command line
  plackup -s FCGI -e 'enable "LighttpdScriptNameFix"' /path/to/app.psgi

=head1 DESCRIPTION

This middleware fixes wrong C<SCRIPT_NAME> and C<PATH_INFO> set by
lighttpd when you mount your app under the root path ("/"). If you use
lighttpd 1.4.23 or later you can instead enable C<fix-root-scriptname>
flag inside C<fastcgi.server> instead of using this middleware.

=head1 CONFIGURATION

=over 4

=item script_name

Even with C<fix-root-scriptname>, lighttpd I<still> sets weird
C<SCRIPT_NAME> and C<PATH_INFO> if you mount your application at C<"">
or something that ends with C</>. Setting C<script_name> option tells
the middleware how to reconstruct the new correct C<SCRIPT_NAME> and
C<PATH_INFO>.

If you mount the app under C</something/>, you should set:

  enable "LighttpdScriptNameFix", script_name => "/something";

and when a request for C</something/a/b?param=1> comes, C<SCRIPT_NAME>
becomes C</something> and C<PATH_INFO> becomes C</a/b>.

C<script_name> option is set to empty by default, which means all the
request path is set to C<PATH_INFO> and it behaves like your fastcgi
application is mounted in the root path.

=back

=head1 AUTHORS

Yury Zavarin

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Handler::FCGI>
L<http://github.com/plack/Plack/issues#issue/68>
L<https://redmine.lighttpd.net/issues/729>

=cut

