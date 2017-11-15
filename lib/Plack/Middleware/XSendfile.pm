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

See L<http://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/sendfile.rb>
for the frontend configuration.

Plack::Middleware::XSendfile does not set the Content-Type header.

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
