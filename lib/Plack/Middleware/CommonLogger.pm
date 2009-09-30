package Plack::Middleware::CommonLogger;
use strict;
use warnings;
use base qw( Plack::Middleware );
__PACKAGE__->mk_accessors(qw( logger ));

use Time::HiRes;
use Plack::Util;
use POSIX;

sub call {
    my $self = shift;
    my($env) = @_;

    my $time = Time::HiRes::gettimeofday;
    my $length = 0;
    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    my($status, $header, $body) = @{$self->app->($env)};

    my $timer_body = Plack::Util::inline_object(
        getline => sub {
            my $line;
            if (ref $body eq 'ARRAY') {
                $line = shift @$body;
            } else {
                $line = $body->getline;
            }
            $length += length $line if defined $line;
            return $line;
        },
        close => sub {
            $body->close if ref $body ne 'ARRAY';

            my $now = Time::HiRes::gettimeofday;
            my $output = sprintf "%s - %s [%s] \"%s %s%s %s\" %d %s %0.4f\n",
                $env->{HTTP_X_FORWARDED_FOR} || $env->{REMOTE_ADDR} || "-",
                $env->{REMOTE_USER} || "-",
                POSIX::strftime("%d/%b/%Y %H:%M:%S", localtime),
                $env->{REQUEST_METHOD},
                $env->{PATH_INFO},
                length $env->{QUERY_STRING} ? "?" . $env->{QUERY_STRING} : '',
                $env->{SERVER_PROTOCOL},
                $status,
                $length == 0 ? "-" : $length,
                $now - $time;

            $logger->($output);
        },
    );

    return [ $status, $header, $timer_body ];
}

1;

__END__

=head1 NAME

Plack::Middleware::CommonLogger - Logs requests using Common Log format

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Middleware qw(CommonLogger);
  use Plack::Builder;

  builder {
      enable Plack::Middleware::CommonLogger;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::CommonLogger is a middleware that forwards every
request to the given app, and logs a line in the Apache common log
format to the logger callback, by default printing to C<psgi.errors>
output stream.

This wraps the response body output stream so some standalone server
optimizations like sendfile(2) will be disabled if you use this
middleware.

This middleware is enabled by default when you run L<plackup> in the
default development mode.

=head1 CONFIGURATION

=over 4

=item logger

  my $logger = Log::Dispatch->new(...);
  enable Plack::Middleware::CommonLogger
      logger => sub { $logger->log(debug => @_) };

Sets the logger callback to log output. By default it uses C<psgi.errors> output stream in the request.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

Rack::CommonLogger

=cut
