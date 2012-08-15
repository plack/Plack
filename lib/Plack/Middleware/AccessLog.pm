package Plack::Middleware::AccessLog;
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( logger format );

use Carp ();
use Plack::Util;

my %formats = (
    common => '%h %l %u %t "%r" %>s %b',
    combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
);

use POSIX ();
use Time::Local ();

my $tzoffset = POSIX::strftime("%z", localtime) !~ /^[+-]\d{4}$/ && do {
    my @t = localtime(time);
    my $s = Time::Local::timegm(@t) - Time::Local::timelocal(@t);
    sprintf '%+03d%02u', int($s/3600), $s % 3600;
};

sub call {
    my $self = shift;
    my($env) = @_;

    my $res = $self->app->($env);

    return $self->response_cb($res, sub {
        my $res = shift;
        my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

        my $content_length = Plack::Util::content_length($res->[2]);
        $logger->( $self->log_line($res->[0], $res->[1], $env, { content_length => $content_length }) );
    });
}

sub log_line {
    my($self, $status, $headers, $env, $opts) = @_;

    my $h = Plack::Util::headers($headers);

    my $strftime = sub {
        my ($fmt, @time) = @_;
        $fmt =~ s/%z/$tzoffset/g if $tzoffset;
        my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
        my $out = POSIX::strftime($fmt, @time);
        POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
        return $out;
    };

    my $block_handler = sub {
        my($block, $type) = @_;
        if ($type eq 'i') {
            $block =~ s/-/_/g;
            my $val = _safe($env->{"HTTP_" . uc($block)});
            return defined $val ? $val : "-";
        } elsif ($type eq 'o') {
            return scalar $h->get($block) || "-";
        } elsif ($type eq 't') {
            return "[" . $strftime->($block, localtime) . "]";
        } else {
            Carp::carp("{$block}$type not supported");
            return "-";
        }
    };


    my %char_handler = (
        '%' => sub { '%' },
        h => sub { $env->{REMOTE_ADDR} || '-' },
        l => sub { '-' },
        u => sub { $env->{REMOTE_USER} || '-' },
        t => sub { "[" . $strftime->('%d/%b/%Y:%H:%M:%S %z', localtime) . "]" },
        r => sub { _safe($env->{REQUEST_METHOD}) . " " . _safe($env->{REQUEST_URI}) .
                   " " . $env->{SERVER_PROTOCOL} },
        s => sub { $status },
        b => sub { $opts->{content_length} || $h->get('Content-Length') || "-" },
        T => sub { $opts->{time} ? int($opts->{time}) : "-" },
        D => sub { $opts->{time} ? $opts->{time} * 1000000 : "-" },
        v => sub { $env->{SERVER_NAME} || '-' },
        V => sub { $env->{HTTP_HOST} || $env->{SERVER_NAME} || '-' },
    );

    my $char_handler = sub {
        my $char = shift;

        my $cb = $char_handler{$char};
        unless ($cb) {
            Carp::carp "\%$char not supported.";
            return "-";
        }
        $cb->($char);
    };

    my $fmt = $self->format || "combined";
    $fmt = $formats{$fmt} if exists $formats{$fmt};

    $fmt =~ s{
        (?:
         \%\{(.+?)\}([a-z]) |
         \%(?:[<>])?([a-zA-Z\%])
        )
    }{ $1 ? $block_handler->($1, $2) : $char_handler->($3) }egx;

    return $fmt . "\n";
}

sub _safe {
    my $string = shift;
    $string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/eg
        if defined $string;
    $string;
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
to specify the log format. This middleware implements a subset of
L<Apache's LogFormat templates|http://httpd.apache.org/docs/2.0/mod/mod_log_config.html>:

   %%    a percent sign
   %h    REMOTE_ADDR from the PSGI environment, or -
   %l    remote logname not implemented (currently always -)
   %u    REMOTE_USER from the PSGI environment, or -
   %t    [local timestamp, in default format]
   %r    REQUEST_METHOD, REQUEST_URI and SERVER_PROTOCOL from the PSGI environment
   %s    the HTTP status code of the response
   %b    content length
   %T    custom field for handling times in subclasses
   %D    custom field for handling sub-second times in subclasses
   %v    SERVER_NAME from the PSGI environment, or -
   %V    HTTP_HOST or SERVER_NAME from the PSGI environment, or -

Some of these format fields are only supported by middleware that subclasses C<AccessLog>.

In addition, custom values can be referenced, using C<%{name}>,
with one of the mandatory modifier flags C<i>, C<o> or C<t>:

   %{variable-name}i    HTTP_VARIABLE_NAME value from the PSGI environment
   %{header-name}o      header-name header
   %{time-format]t      localtime in the specified strftime format

=item logger

  my $logger = Log::Dispatch->new(...);
  enable "Plack::Middleware::AccessLog",
      logger => sub { $logger->log(level => 'debug', message => @_) };

Sets a callback to print log message to. It prints to the C<psgi.errors>
output stream by default.

=back

=head1 SEE ALSO

L<http://httpd.apache.org/docs/2.2/mod/mod_log_config.html> Rack::CustomLogger

=cut

