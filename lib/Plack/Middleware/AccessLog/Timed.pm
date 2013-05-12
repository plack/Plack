package Plack::Middleware::AccessLog::Timed;
use strict;
use warnings;
use parent qw( Plack::Middleware::AccessLog );

use Time::HiRes;
use Plack::Util;

sub call {
    my $self = shift;
    my($env) = @_;

    my $time = Time::HiRes::gettimeofday;
    my $length = 0;
    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    my $res = $self->app->($env);

    return $self->response_cb($res, sub {
        my $res = shift;
        my($status, $header, $body) = @$res;

        if (!defined $body) {
            my $length;

            return sub {
                my $line = shift;
                
                $length += length $line if defined $line;

                unless( defined $line ) {
                    my $now = Time::HiRes::gettimeofday;
                    $logger->( $self->log_line($status, $header, $env, { time => $now - $time, content_length => $length }) );
                }

                return $line;
            };
        }

        my $getline = ref $body eq 'ARRAY' ? sub { shift @$body } : sub { $body->getline };

        my $timer_body = Plack::Util::inline_object(
            getline => sub {
                my $line = $getline->();
                $length += length $line if defined $line;
                return $line;
            },
            close => sub {
                $body->close if ref $body ne 'ARRAY';

                my $now = Time::HiRes::gettimeofday;
                $logger->( $self->log_line($status, $header, $env, { time => $now - $time, content_length => $length }) );
            },
        );

        @$res = ($status, $header, $timer_body);
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::AccessLog::Timed - Logs requests with time and accurate body size

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "Plack::Middleware::AccessLog::Timed",
          format => "%v %h %l %u %t \"%r\" %>s %b %D";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::AccessLog::Timed is a subclass of
L<Plack::Middleware::AccessLog> but uses a wrapped body handle to get the
actual response body size C<%b> (even if it's not a chunk of array or
a real filehandle) and the time taken to serve the request: C<%T> or
C<%D>.

This wraps the response body output stream to capture the time taken
for the PSGI server to read the whole response body.

This would mean, if the middleware is in use, it will prevent some
server-side optimizations like sendfile(2) from working, as well as
middleware like L<Plack::Middleware::ContentLength> can't guess the
body size out of the file handle.

If all you want is to capture the time taken in your PSGI application
and do not want the wrapped body behavior described above, consider instead
applying L<Plack::Middleware::Runtime> and using L<Plack::Middleware::AccessLog>
to log the C<X-Runtime> header.

=head1 CONFIGURATION

Same as L<Plack::Middleware::AccessLog>.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware::AccessLog>

L<Plack::Middleware::Runtime>

=cut
