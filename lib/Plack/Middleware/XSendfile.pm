package Plack::Middleware::XSendfile;
use strict;
use warnings;
use parent qw(Plack::Middleware);

use Plack::Util;
use Scalar::Util;
use Plack::Util::Accessor qw( variation );

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        my($status, $headers, $body) = @$res;
        return unless defined $body;

        if (Scalar::Util::blessed($body) && $body->can('path')) {
            my $type = $self->_variation($env) || '';
            my $h = Plack::Util::headers($headers);
            if ($type && !$h->exists($type)) {
                if ($type eq 'X-Accel-Redirect') {
                    my $path = $body->path;
                    my $url = $self->map_accel_path($env, $path);
                    $h->set($type => $url) if $url;
                    $h->set('Content-Length', 0);
                    $body = [];
                } elsif ($type eq 'X-Sendfile' or $type eq 'X-Lighttpd-Send-File') {
                    my $path = $body->path;
                    $h->set($type => $path) if defined $path;
                    $h->set('Content-Length', 0);
                    $body = [];
                } else {
                    $env->{'psgi.errors'}->print("Unknown x-sendfile variation: $type");
                }
            }
        }

        @$res = ( $status, $headers, $body );
    });
}

sub map_accel_path {
    my($self, $env, $path) = @_;

    if (my $mapping = $env->{HTTP_X_ACCEL_MAPPING}) {
        my($internal, $external) = split /=/, $mapping, 2;
        $path =~ s!^\Q$internal\E!$external!i;
    }

    return $path;
}

sub _variation {
    my($self, $env) = @_;
    $self->variation || $env->{'plack.xsendfile.type'} || $env->{HTTP_X_SENDFILE_TYPE};
}

1;

__END__

=head1 NAME

Plack::Middleware::XSendfile - Sets X-Sendfile (or a like) header for frontends

=head1 SYNOPSIS

  enable "Plack::Middleware::XSendfile";

=head1 DESCRIPTION

When the body is a blessed reference with a C<path> method, then the
return value of that method is used to set the X-Sendfile header.

The body is set to an empty list, and the Content-Length header is
set to 0.

If the X-Sendfile header is already set, then the body and
Content-Length will be untouched.

You should use L<IO::File::WithPath> or L<Plack::Util>'s
C<set_io_path> to add C<path> method to an IO object in the body.

See L<https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile>
for frontend configuration examples.

Plack::Middleware::XSendfile does not set the Content-Type header.

=head1 FRONTEND CONFIGURATION

=head2 Nginx

Nginx supports C<X-Accel-Redirect>. Configure an internal location and
pass the C<X-Accel-Mapping> header to the backend so the middleware can
rewrite filesystem paths into internal URLs:

  location ~ /files/(.*) {
      internal;
      alias /var/www/$1;
  }

  location / {
      proxy_pass         http://127.0.0.1:5000/;
      proxy_set_header   X-Sendfile-Type     X-Accel-Redirect;
      proxy_set_header   X-Accel-Mapping     /var/www/=/files/;
  }

C<X-Accel-Mapping> tells the middleware which filesystem prefix to replace
and what internal URL prefix to use instead.

=head2 Apache

Enable mod_xsendfile (L<https://tn123.org/mod_xsendfile/>) and set the
request header so the middleware activates:

  RequestHeader Set X-Sendfile-Type X-Sendfile
  XSendFile on

=head2 lighttpd

  proxy-core.allow-x-sendfile = "enable"
  proxy-core.rewrite-request = (
      "X-Sendfile-Type" => (".*" => "X-Sendfile")
  )

=head1 SECURITY

This middleware reads the C<X-Accel-Mapping> and C<X-Sendfile-Type> values
from request headers, which are expected to be injected by a trusted frontend
proxy. B<The Plack backend must not be directly reachable by untrusted
clients.> If a client can send these headers directly, they can influence which
files the frontend server serves.

To defend in depth with nginx, use C<proxy_ignore_headers> to prevent any
client-supplied values from passing through, and rely solely on
C<proxy_set_header> directives in your nginx configuration to supply the
correct values.

=head1 CONFIGURATION

=over 4

=item variation

The header tag to use. If unset, the environment key
C<plack.xsendfile.type> will be used, then the C<HTTP_X_SENDFILE_TYPE>
header.

Supported values are:

=over

=item * C<X-Accel-Redirect>

=item * C<X-Lighttpd-Send-File>

=item * C<X-Sendfile>.

=back

An unsupport value will log an error.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
