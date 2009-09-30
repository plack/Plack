package Plack::Middleware::AccessLog;
use strict;
use warnings;
use base qw( Plack::Middleware );

__PACKAGE__->mk_accessors(qw( logger format ));

use Carp ();

my %formats = (
    common => "%h %l %u %t \"%r\" %>s %b",
    combined => "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"",
);

use POSIX;

sub call {
    my $self = shift;
    my($env) = @_;

    my $res = $self->app->($env);

    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    my $content_length = Plack::Util::content_length($res->[2]);
    $logger->( $self->log_line($res->[0], $res->[1], $env, { content_length => $content_length }) );

    return $res;
}

sub log_line {
    my($self, $status, $headers, $env, $opts) = @_;

    my $h = Plack::Util::headers($headers);

    my $block_handler = sub {
        my($block, $type) = @_;
        if ($type eq 'i') {
            $block =~ s/-/_/;
            return $env->{"HTTP_" . uc($block)} || "-";
        } elsif ($type eq 'o') {
            return scalar $h->get($block) || "-";
        } elsif ($type eq 't') {
            return "[" . POSIX::strftime($block, localtime) . "]";
        } else {
            Carp::carp("{$block}$type not supported");
            return "-";
        }
    };

    my %char_handler = (
        '%' => sub { '%' },
        h => sub { $env->{HTTP_X_FORWARDED_FOR} || $env->{REMOTE_ADDR} || '-' },
        l => sub { '-' },
        u => sub { $env->{REMOTE_USER} || '-' },
        t => sub { "[" . POSIX::strftime("%d/%b/%Y %H:%M:%S", localtime) . "]" },
        r => sub { $env->{REQUEST_METHOD} . " " . $env->{PATH_INFO} .
                   (length $env->{QUERY_STRING} ? '?' . $env->{QUERY_STRING} : '') .
                   " " . $env->{SERVER_PROTOCOL} },
        s => sub { $status },
        b => sub { $opts->{content_length} || $h->get('Content-Length') || "-" },
        T => sub { $opts->{time} ? int($opts->{time}) : "-" },
        D => sub { $opts->{time} || "-" },
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
         \%\{([\w\-]+)\}([a-z]) |
         \%(?:[<>])?([a-z\%])
        )
    }{ $1 ? $block_handler->($1, $2) : $char_handler->($3) }egx;

    return $fmt;
}

__END__

=head1 NAME

Plack::Middleware::AccessLog - Logs requests like Apache's log format

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Middleware qw(AccessLog);
  use Plack::Builder;

  builder {
      enable Plack::Middleware::AccessLog format => "combined";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::AccessLog forwards the request to the given app and
logs request and response details to the logger callback. The format
can be specified using Apache-like format strings (or C<combined> or
C<common> for the default formats).

This middleware uses calculatable content-length by cheking body type,
and can not log the time taken to serve requests. It also logs the
request B<before> the response is actually sent to the client. Use
L<Plack::Middleware::AccessLog::Timed> if you want to log details
B<after> the response is transmitted (more like a real web server) to
the client.

This middleware is enabled by default when you run L<plackup> as a
default C<development> environment.

=head1 CONFIGURATION

=over 4

=item format

  enable Plack::Middleware::AccessLog
      format => "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"";

=item logger

  my $logger = Log::Dispatch->new(...);
  enable Plack::Middleware::AccessLog
      logger => sub { $logger->log(debug => @_) };

=back

=head1 SEE ALSO

Rack::CustomLogger

=cut

