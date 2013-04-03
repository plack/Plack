package Plack::Middleware::AccessLog;
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( logger format compiled_format);
use Apache::LogFormat::Compiler;

my %formats = (
    common => '%h %l %u %t "%r" %>s %b',
    combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
);

sub prepare_app {
    my $self = shift;
    my $fmt = $self->format || "combined";
    $fmt = $formats{$fmt} if exists $formats{$fmt};
    $self->compiled_format(Apache::LogFormat::Compiler->new($fmt));
}

sub call {
    my $self = shift;
    my($env) = @_;

    my $res = $self->app->($env);

    if ( ref($res) && ref($res) eq 'ARRAY' ) {
        my $content_length = Plack::Util::content_length($res->[2]);
        my $log_line = $self->log_line($res->[0], $res->[1], $env, { content_length => $content_length });
        if ( my $logger = $self->logger ) {
            $logger->($log_line);
        }
        else {
            $env->{'psgi.errors'}->print($log_line);
        }  
        return $res;
    }

    return $self->response_cb($res, sub {
        my $res = shift;
        my $content_length = Plack::Util::content_length($res->[2]);
        my $log_line = $self->log_line($res->[0], $res->[1], $env, { content_length => $content_length });
        if ( my $logger = $self->logger ) {
            $logger->($log_line);
        }
        else {
            $env->{'psgi.errors'}->print($log_line);
        }  
    });
}

sub log_line {
    my($self, $status, $headers, $env, $opts) = @_;

    $self->compiled_format->log_line(
        $env,
        [$status,$headers],
        $opts->{content_length},
        $opts->{time}
    );
}

1;

__END__

=for stopwords
LogFormat

=head1 NAME

Plack::Middleware::AccessLog - Logs requests like Apache's log format

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "Plack::Middleware::AccessLog", format => "combined";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::AccessLog forwards the request to the given app and
logs request and response details to the logger callback. The format
can be specified using Apache-like format strings (or C<combined> or
C<common> for the default formats). If none is specified C<combined> is
used.

This middleware uses calculable Content-Length by checking body type,
and cannot log the time taken to serve requests. It also logs the
request B<before> the response is actually sent to the client. Use
L<Plack::Middleware::AccessLog::Timed> if you want to log details
B<after> the response is transmitted (more like a real web server) to
the client.

This middleware is enabled by default when you run L<plackup> as a
default C<development> environment.

=head1 CONFIGURATION

=over 4

=item format

  enable "Plack::Middleware::AccessLog",
      format => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';

Takes a format string (or a preset template C<combined> or C<custom>)
to specify the log format. This middleware uses L<Apache::LogFormat::Compiler> to
generate access_log lines. See more details on perldoc L<Apache::LogFormat::Compiler>

   %%    a percent sign
   %h    REMOTE_ADDR from the PSGI environment, or -
   %l    remote logname not implemented (currently always -)
   %u    REMOTE_USER from the PSGI environment, or -
   %t    [local timestamp, in default format]
   %r    REQUEST_METHOD, REQUEST_URI and SERVER_PROTOCOL from the PSGI environment
   %s    the HTTP status code of the response
   %b    content length of the response
   %T    custom field for handling times in subclasses
   %D    custom field for handling sub-second times in subclasses
   %v    SERVER_NAME from the PSGI environment, or -
   %V    HTTP_HOST or SERVER_NAME from the PSGI environment, or -
   %p    SERVER_PORT from the PSGI environment
   %P    the worker's process id
   %m    REQUEST_METHOD from the PSGI environment
   %U    PATH_INFO from the PSGI environment
   %q    QUERY_STRING from the PSGI environment
   %H    SERVER_PROTOCOL from the PSGI environment

Some of these format fields are only supported by middleware that subclasses C<AccessLog>.

In addition, custom values can be referenced, using C<%{name}>,
with one of the mandatory modifier flags C<i>, C<o> or C<t>:

   %{variable-name}i    HTTP_VARIABLE_NAME value from the PSGI environment
   %{header-name}o      header-name header in the response
   %{time-format]t      localtime in the specified strftime format

=item logger

  my $logger = Log::Dispatch->new(...);
  enable "Plack::Middleware::AccessLog",
      logger => sub { $logger->log(level => 'debug', message => @_) };

Sets a callback to print log message to. It prints to the C<psgi.errors>
output stream by default.

=back

=head1 SEE ALSO

L<Apache::LogFormat::Compiler>, L<http://httpd.apache.org/docs/2.2/mod/mod_log_config.html> Rack::CustomLogger

=cut

